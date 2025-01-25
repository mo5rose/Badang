$extensions = @(
    "ms-azuretools.vscode-docker",
    "ms-vscode-remote.remote-wsl",
    "ms-vscode-remote.remote-containers",
    "ms-python.python",
    "ms-python.vscode-pylance",
    "redhat.vscode-yaml",
    "eamodio.gitlens",
    "GitHub.copilot",
    "ms-azuretools.vscode-azurefunctions",
    "hashicorp.terraform",
    "ms-kubernetes-tools.vscode-kubernetes-tools"
)

foreach ($extension in $extensions) {
    code --install-extension $extension
}