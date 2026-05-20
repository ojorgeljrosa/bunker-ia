# 🛡️ Bunker IA - Agência de Marketing

Este é um ambiente de desenvolvimento isolado e persistente, projetado para operar agentes de IA (Claude Code, Gemini, OpenCode, Hermes) com segurança e alta performance.

## 🚀 Tecnologias Inclusas
- **OS:** Ubuntu 22.04 LTS (Zsh como Shell padrão)
- **Rede:** Tailscale (Acesso remoto seguro)
- **Linguagens:** Python 3.10/3.11, Node.js 20
- **Agentes de IA:** Claude Code, Gemini CLI, OpenCode, Hermes Agent
- **Banco de Dados:** PostgreSQL (Embutido via Paperclip)
- **Interface Web:** code-server (VS Code Web), Filebrowser, Hermes Dashboard

---

## 🛠️ Instalação e Deploy (Easypanel)

1. **Criar Serviço:** No Easypanel, crie um novo serviço do tipo `App` usando este repositório.
2. **Configurar Volume:** - Vá em **Volumes** e monte um volume chamado `jorge-home` no caminho `/home/jorge`. Isso garante que seus arquivos e logins não sumam.
3. **Variáveis de Ambiente:**
   - `SSH_PUBLIC_KEY`: Cole sua chave pública (`ssh-rsa ...`) para acesso via Termius.
   - `ANTHROPIC_API_KEY`: Para usar o Claude Code.
   - `GEMINI_API_KEY`: Para usar o Gemini CLI.
   - `NVIDIA_API_KEY`: Para usar o Hermes Agent (ou outro provider).

---

## 🏁 Configuração Pós-Instalação (Obrigatório)

Após o container subir pela primeira vez, siga estes passos para ativar o bunker:

### 1. Ativar a Rede Tailscale
O bunker não estará acessível até que você o autorize na sua rede privada.
1. No terminal do Easypanel, rode:
   ```bash
   tailscale up --authkey=SUA_AUTH_KEY_AQUI
   ```
   *(Ou rode apenas `tailscale up` e clique no link gerado para autorizar no browser).*

### 2. Login Único no GitHub (Ponte Git)
A integração já está pré-configurada. Você só precisa carimbar o passaporte:
1. No terminal (já via Termius), rode:
   ```bash
   gh auth login
   ```
2. Escolha `GitHub.com` -> `HTTPS` -> `Login with a web browser`.
3. Copie o código de 8 dígitos e cole no link que aparecerá no seu Mac.
4. **Pronto!** O Git já está integrado e não pedirá mais senhas.

### 3. Configurar Identidade Git
Para que seus commits saiam com seu nome:
```bash
git config --global user.name "Jorge"
git config --global user.email "seu-email@agencia.com"
```

### 4. Definir Senha do Usuário (Opcional)
Para usar `sudo` ou trocar de usuário manualmente:
```bash
sudo passwd jorge
```

---

## 🌐 Serviços Web e Dashboards

Todos os serviços abaixo são acessíveis via Tailscale no IP do seu container (ex: `http://100.x.x.x:PORTA`).

| Serviço | Porta | Descrição |
| :--- | :--- | :--- |
| **Filebrowser** | `8081` | Gerenciador visual de arquivos. Login padrão: `admin` / `admin` |
| **code-server** | `8082` | VS Code completo no navegador. Senha em `~/.config/code-server/config.yaml` |
| **Hermes Dashboard** | `9119` | Painel de controle do agente Hermes (API Keys, Sessões, Kanban) |
| **Paperclip** | `3100/3101` | Sistema de coordenação de agentes e tarefas |
| **OpenCode** | `3100` | Interface web do OpenCode (integrada ao Paperclip) |

---

## 📂 Organização de Arquivos
- `~/repositorios`: Pasta sugerida para clonar seus projetos da agência.
- `~/.zshrc`: Configurações visuais e aliases do terminal (Persistente).
- `~/.ssh`: Chaves autorizadas (Persistente).

## 🛡️ Segurança
- O acesso SSH root está desativado. Use sempre o usuário `jorge`.
- A porta 22 está exposta, mas protegida pela sua chave SSH e pela camada do Tailscale.
- **Importante:** Nunca exponha as portas 8081, 8082 ou 9119 para a internet pública. Use apenas via Tailscale.
