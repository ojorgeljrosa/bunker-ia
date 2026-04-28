FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Dependências de sistema e chaves
RUN apt update && apt install -y \
    curl git zsh sudo vim wget build-essential tmux \
    python3 python3-pip python3-venv fzf \
    software-properties-common gnupg apt-transport-https \
    && mkdir -p /etc/apt/keyrings

# Correção FZF
RUN mkdir -p /usr/share/doc/fzf/examples/ && \
    ln -s /usr/share/fzf/key-bindings.zsh /usr/share/doc/fzf/examples/key-bindings.zsh

# 2. Repositórios (Tailscale e GitHub CLI)
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list

# 3. Pacotes de rede e bibliotecas para Browsers
RUN apt update && apt install -y tailscale gh \
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libxkbcommon0 libxcomposite1 libxdamage1 libxrandr2 \
    libgbm1 libasound2 libpangocairo-1.0-0 libpango-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 4. Node.js e Ferramentas Globais
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt install -y nodejs && \
    npm install -g pnpm typescript ts-node nodemon pm2 \
    @anthropic-ai/claude-code \
    @google/generative-ai \
    playwright \
    opencode-ai

# 5. Instalação via CURL (OpenCode)
RUN curl -fsSL https://opencode.ai/install | bash

# 6. Configuração do Usuário Jorge e ZSH
RUN useradd -m -s /bin/zsh jorge && \
    echo "jorge ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 7. SSH Server (Instalação e config básica)
RUN apt update && apt install -y openssh-server && \
    mkdir -p /var/run/sshd && \
    echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config

# 8. Instalação Gemini Oficial
RUN npm install -g @google/gemini-cli

# 9. Configurações de usuário (Executado como Jorge)
USER jorge
WORKDIR /home/jorge

# Instalação dos Browsers (Playwright)
RUN npx playwright install --with-deps chromium

# --- CONFIGURAÇÃO DO TMUX (Padrão Ctrl+B + Melhorias de Visual e Mouse) ---
RUN printf "set -s escape-time 0\n\
set -g default-terminal \"screen-256color\"\n\
set -ga terminal-overrides \",xterm-256color:Tc\"\n\
set -g mouse on\n\
set -g history-limit 50000\n\
set -q -g status-utf8 on\n\
setw -q -g utf8 on\n" > ~/.tmux.conf

# --- CONFIGURAÇÃO DO ZSH (Aliases e Funções de IA atualizadas) ---
RUN printf "\n\
run_ai_project() {\n\
    local tool=\$1\n\
    local cmd=\$2\n\
    local project=\${3:-\"padrao\"}\n\
    local session_name=\"\${tool}-\${project}\"\n\
    tmux -u attach-session -t \"\$session_name\" 2>/dev/null || tmux -u new-session -s \"\$session_name\" \"\$cmd\"\n\
}\n\
alias claude=\"run_ai_project \\\"claude\\\" \\\"claude\\\"\"\n\
alias opencode=\"run_ai_project \\\"opencode\\\" \\\"opencode\\\"\"\n\
alias gemini=\"run_ai_project \\\"gemini\\\" \\\"gemini\\\"\"\n" >> ~/.zshrc

# 10. Script de Inicialização Mestre (Versão Elite Consolidada)
USER root
RUN printf "#!/bin/bash\n\
# 1. Ajuste de Permissões Críticas (StrictModes e Ownership)\n\
mkdir -p /var/lib/tailscale /home/jorge/.ssh\n\
chown -R jorge:jorge /home/jorge\n\
chmod 755 /home/jorge\n\
chmod 700 /home/jorge/.ssh\n\
\n\
# 2. Persistência de SSH Fingerprint\n\
if [ ! -f \"/var/lib/tailscale/ssh_host_ed25519_key\" ]; then\n\
    echo 'Gerando chaves SSH iniciais...'\n\
    ssh-keygen -A\n\
    cp /etc/ssh/ssh_host_* /var/lib/tailscale/\n\
else\n\
    echo 'Restaurando chaves SSH do volume...'\n\
    cp /var/lib/tailscale/ssh_host_* /etc/ssh/\n\
    chmod 600 /etc/ssh/ssh_host_*_key\n\
fi\n\
\n\
# 3. Injeção da Chave Pública e Integração Git\n\
if [ ! -z \"\$SSH_PUBLIC_KEY\" ]; then\n\
    echo \"\$SSH_PUBLIC_KEY\" > /home/jorge/.ssh/authorized_keys\n\
    chown jorge:jorge /home/jorge/.ssh/authorized_keys\n\
    chmod 600 /home/jorge/.ssh/authorized_keys\n\
fi\n\
\n\
# Deixa o Git pronto para usar o login do GitHub CLI automaticamente\n\
sudo -u jorge git config --global credential.helper \"!gh auth git-credential\"\n\
\n\
# 4. Compatibilidade RSA (Ubuntu 22.04+)\n\
grep -qX \"PubkeyAcceptedAlgorithms +ssh-rsa\" /etc/ssh/sshd_config || echo \"PubkeyAcceptedAlgorithms +ssh-rsa\" >> /etc/ssh/sshd_config\n\
\n\
service ssh start\n\
tailscaled --tun=userspace-networking --state=/var/lib/tailscale/tailscaled.state > /dev/null 2>&1 &\n\
echo '------------------------------------'\n\
echo '  Bunker IA 100%% operacional, Jorge! '\n\
echo '  Acesso SSH e Git: Habilitados      '\n\
echo '------------------------------------'\n\
tail -f /dev/null\n" > /start.sh

RUN chmod +x /start.sh
EXPOSE 22
CMD ["/bin/bash", "/start.sh"]
