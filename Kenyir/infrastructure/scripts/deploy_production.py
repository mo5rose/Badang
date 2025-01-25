# infrastructure/scripts/deploy_production.py
import subprocess
import sys
import logging
from typing import List, Dict

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class ProductionDeployer:
    def __init__(self):
        self.components = [
            "storage",
            "processing",
            "query",
            "metadata",
            "orchestration",
            "monitoring"
        ]
        
    def check_prerequisites(self) -> bool:
        required_commands = [
            "kubectl",
            "docker",
            "aws",
            "terraform"
        ]
        
        for cmd in required_commands:
            try:
                subprocess.run([cmd, "--version"], 
                             check=True, 
                             capture_output=True)
            except subprocess.CalledProcessError:
                logger.error(f"Missing required command: {cmd}")
                return False
        return True
    
    def deploy_infrastructure(self):
        try:
            subprocess.run([
                "terraform",
                "-chdir=infrastructure/terraform/production",
                "apply",
                "-auto-approve"
            ], check=True)
        except subprocess.CalledProcessError as e:
            logger.error(f"Infrastructure deployment failed: {e}")
            sys.exit(1)
    
    def deploy_components(self):
        for component in self.components:
            try:
                logger.info(f"Deploying {component}...")
                subprocess.run([
                    "kubectl",
                    "apply",
                    "-f",
                    f"infrastructure/kubernetes/production/{component}"
                ], check=True)
            except subprocess.CalledProcessError as e:
                logger.error(f"Failed to deploy {component}: {e}")
                return False
        return True
    
    def verify_deployment(self) -> Dict[str, bool]:
        status = {}
        for component in self.components:
            pods = subprocess.run([
                "kubectl",
                "get",
                "pods",
                "-l",
                f"app={component}",
                "-o",
                "jsonpath='{.items[*].status.phase}'"
            ], capture_output=True, text=True)
            
            status[component] = "Running" in pods.stdout
        return status
    
    def run_deployment(self):
        logger.info("Starting production deployment...")
        
        if not self.check_prerequisites():
            logger.error("Prerequisites check failed")
            return False
            
        self.deploy_infrastructure()
        
        if not self.deploy_components():
            logger.error("Component deployment failed")
            return False
            
        status = self.verify_deployment()
        
        if all(status.values()):
            logger.info("Deployment completed successfully")
            return True
        else:
            failed = [k for k, v in status.items() if not v]
            logger.error(f"Deployment failed for components: {failed}")
            return False

if __name__ == "__main__":
    deployer = ProductionDeployer()
    success = deployer.run_deployment()
    sys.exit(0 if success else 1)