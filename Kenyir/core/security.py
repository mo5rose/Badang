# core/security.py
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from cryptography.fernet import Fernet

class SecurityManager:
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self._initialize_security()

    def _initialize_security(self):
        """Initialize security components"""
        self.credential = DefaultAzureCredential()
        self.secret_client = SecretClient(
            vault_url=self.config['key_vault_url'],
            credential=self.credential
        )
        self._setup_encryption()
        self._setup_rbac()
        self._setup_network_security()

    def _setup_encryption(self):
        """Set up encryption at rest and in transit"""
        self.encryption_key = self.secret_client.get_secret('data-encryption-key')
        self.fernet = Fernet(self.encryption_key.value.encode())

    def encrypt_sensitive_data(self, data: bytes) -> bytes:
        """Encrypt sensitive data"""
        return self.fernet.encrypt(data)

    def decrypt_sensitive_data(self, encrypted_data: bytes) -> bytes:
        """Decrypt sensitive data"""
        return self.fernet.decrypt(encrypted_data)