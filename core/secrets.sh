DockerSecrets() {
    # Default values
    local SECRET_NAME=""
    local SECRET_TYPE=""
    local SECRET_PATH="../../secrets"
    local KEY_TYPE="rsa"
    local KEY_BITS=4096
    local PASSWORD_LENGTH=32

    # Help function
    ShowHelp() {
        echo "Docker Secrets Helper Function"
        echo "Usage: DockerSecrets [OPTIONS]"
        echo "Options:"
        echo "  -n, --name           Secret name (required)"
        echo "  -t, --type           Secret type (ssh-key, password) (required for new secrets)"
        echo "  -p, --path           Path to store secrets (default: ../../secrets)"
        echo "  --key-type          SSH key type (rsa, ed25519) (default: rsa)"
        echo "  --key-bits          SSH key bits for RSA (default: 4096)"
        echo "  --password-length   Length of generated password (default: 32)"
        echo "  --list              List all available secrets"
        echo "  -h, --help           Show this help message"
    }

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -n|--name)
                SECRET_NAME="$2"
                shift 2
                ;;
            -t|--type)
                SECRET_TYPE="$2"
                shift 2
                ;;
            -p|--path)
                SECRET_PATH="$2"
                shift 2
                ;;
            --key-type)
                KEY_TYPE="$2"
                shift 2
                ;;
            --key-bits)
                KEY_BITS="$2"
                shift 2
                ;;
            --password-length)
                PASSWORD_LENGTH="$2"
                shift 2
                ;;
            --list)
                LIST_SECRETS=true
                shift
                ;;
            -h|--help)
                ShowHelp
                return 0
                ;;
            *)
                echo "Unknown option: $1"
                ShowHelp
                return 1
                ;;
        esac
    done

    # Create secrets directory if it doesn't exist
    mkdir -p "$SECRET_PATH"

    # List secrets if requested
    if [[ "$LIST_SECRETS" = true ]]; then
        echo "Available secrets in $SECRET_PATH:"
        if [[ -d "$SECRET_PATH" ]]; then
            find "$SECRET_PATH" -type f -not -name "*.pub" -exec basename {} \;
        else
            echo "No secrets directory found"
        fi
        return 0
    fi

    # Validate inputs
    if [[ -z "$SECRET_NAME" ]]; then
        echo "Error: Secret name is required"
        ShowHelp
        return 1
    fi

    # Function to generate a random password
    GeneratePassword() {
        local length=$1
        # Generate password using OpenSSL with special characters, numbers, and letters
        openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@#$%^&*()_+=' | head -c "$length"
    }

    # Function to generate SSH key pair
    GenerateSSHKey() {
        local name=$1
        local type=$2
        local bits=$3
        local key_path="$SECRET_PATH/$name"

        if [[ "$type" == "ed25519" ]]; then
            ssh-keygen -t ed25519 -f "$key_path" -N "" -C "docker-generated-key-$name"
        else
            ssh-keygen -t rsa -b "$bits" -f "$key_path" -N "" -C "docker-generated-key-$name"
        fi

        # Set appropriate permissions
        chmod 600 "$key_path"
        chmod 644 "$key_path.pub"
    }

    # Check if secret already exists
    if [[ -f "$SECRET_PATH/$SECRET_NAME" || -f "$SECRET_PATH/$SECRET_NAME.pub" ]]; then
        # Return existing secret
        if [[ -f "$SECRET_PATH/$SECRET_NAME" && ! -f "$SECRET_PATH/$SECRET_NAME.pub" ]]; then
            # Password secret
            cat "$SECRET_PATH/$SECRET_NAME"
        elif [[ -f "$SECRET_PATH/$SECRET_NAME" && -f "$SECRET_PATH/$SECRET_NAME.pub" ]]; then
            # SSH key secret
            cat "$SECRET_PATH/$SECRET_NAME"
        fi
        return 0
    fi

    # If secret doesn't exist, we need the type to generate it
    if [[ -z "$SECRET_TYPE" ]]; then
        echo "Error: Secret type is required for generating new secret"
        ShowHelp
        return 1
    fi

    # Generate new secret
    case "$SECRET_TYPE" in
        "ssh-key")
            echo "Generating new SSH key pair: $SECRET_NAME" >&2
            GenerateSSHKey "$SECRET_NAME" "$KEY_TYPE" "$KEY_BITS"
            cat "$SECRET_PATH/$SECRET_NAME"
            ;;
        "password")
            echo "Generating new password: $SECRET_NAME" >&2
            local password=$(GeneratePassword "$PASSWORD_LENGTH")
            echo "$password" > "$SECRET_PATH/$SECRET_NAME"
            chmod 600 "$SECRET_PATH/$SECRET_NAME"
            echo "$password"
            ;;
        *)
            echo "Error: Invalid secret type. Supported types: ssh-key, password" >&2
            return 1
            ;;
    esac
}
