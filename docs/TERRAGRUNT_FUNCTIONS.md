# Guía Completa de Funciones de Terragrunt

Esta guía explica las funciones más usadas en Terragrunt HCL, con ejemplos prácticos y casos de uso reales.

## Tabla de Contenidos

- [Funciones de Búsqueda de Archivos](#funciones-de-búsqueda-de-archivos)
- [Funciones de Lectura de Archivos](#funciones-de-lectura-de-archivos)
- [Funciones de Path](#funciones-de-path)
- [Funciones de Dependency](#funciones-de-dependency)
- [Funciones de Locals](#funciones-de-locals)
- [Funciones de Terraform](#funciones-de-terraform)
- [Funciones de Environment](#funciones-de-environment)
- [Funciones de Comandos](#funciones-de-comandos)
- [Funciones AWS](#funciones-aws)
- [Funciones de Utilidad](#funciones-de-utilidad)
- [Patrones Comunes](#patrones-comunes)
- [Ejemplos Completos](#ejemplos-completos)

---

## Funciones de Búsqueda de Archivos

### `find_in_parent_folders()`

**Propósito**: Busca un archivo subiendo en la jerarquía de directorios hasta encontrarlo.

**Uso común**: Incluir configuraciones compartidas que están en directorios padres.

**Sintaxis**:
```hcl
find_in_parent_folders()                    # Busca terragrunt.hcl
find_in_parent_folders("root.hcl")          # Busca archivo específico
find_in_parent_folders("root.hcl", "/")     # Con directorio raíz por defecto
```

**Ejemplo Práctico**:

```hcl
# En config/eu-west-1/dev/vpc/terragrunt.hcl

# Incluir configuración del root
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# Incluir common.hcl: aws_region, environment, account_id, project_name, default_tags
# dirname(find_in_parent_folders("region.hcl")) → config/eu-west-1/
include "common" {
  path           = "${dirname(find_in_parent_folders("region.hcl"))}/_env/common.hcl"
  expose         = true
  merge_strategy = "no_merge"
}
```

**Estructura de ejemplo**:
```
config/
├── root.hcl                          ← find_in_parent_folders("root.hcl")
└── eu-west-1/
    ├── region.hcl                    ← find_in_parent_folders("region.hcl")
    ├── _env/
    │   ├── common.hcl                ← variables de identidad centralizadas
    │   ├── dev.hcl                   ← config específica del entorno
    │   ├── pre.hcl
    │   └── pro.hcl
    ├── dev/
    │   ├── account.hcl               ← find_in_parent_folders("account.hcl")
    │   └── vpc/
    │       └── terragrunt.hcl        ← Desde aquí busca hacia arriba
    ├── pre/
    │   ├── account.hcl
    │   └── vpc/terragrunt.hcl
    └── pro/
        ├── account.hcl
        └── vpc/terragrunt.hcl
```

---

## Funciones de Lectura de Archivos

### `read_terragrunt_config()`

**Propósito**: Lee y parsea un archivo HCL de Terragrunt, devolviendo su contenido como objeto.

**Sintaxis**:
```hcl
read_terragrunt_config(path)
```

**Ejemplo Práctico**:

```hcl
# config/eu-west-1/region.hcl
locals {
  aws_region = basename(get_terragrunt_dir())  # "eu-west-1" derivado del nombre de carpeta
}

# config/eu-west-1/dev/account.hcl
locals {
  aws_account_id = "123456789012"
  account_name   = "myapp-dev"
  project_name   = "myapp"
}

# config/root.hcl — región y entorno desde el path, cuenta desde account.hcl
locals {
  # path_relative_to_include() desde eu-west-1/dev/vpc → ["eu-west-1", "dev", "vpc"]
  path_parts   = split("/", path_relative_to_include())
  aws_region   = local.path_parts[0]  # "eu-west-1"
  environment  = local.path_parts[1]  # "dev"

  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.aws_account_id
  project_name = local.account_vars.locals.project_name
}
```

### `file()` y `fileexists()`

**Propósito**: Lee archivos de texto o verifica su existencia.

**Sintaxis**:
```hcl
file(path)                 # Lee contenido del archivo
fileexists(path)           # true si existe, false si no
```

**Ejemplo Práctico**:

```hcl
locals {
  # Leer un archivo de texto
  ssh_key = file("~/.ssh/id_rsa.pub")

  # Leer archivo condicional
  custom_config = fileexists("custom.yaml") ? file("custom.yaml") : ""

  # Leer secrets si existen
  use_secrets = fileexists(".secrets.env")
}
```

### `jsondecode()` y `yamldecode()`

**Propósito**: Parsear archivos JSON o YAML.

**Sintaxis**:
```hcl
jsondecode(string)
yamldecode(string)
```

**Ejemplo Práctico**:

```hcl
# config.json
# {
#   "database_size": "db.t3.medium",
#   "backup_retention": 7
# }

# config.yaml
# features:
#   monitoring: true
#   logging: true

locals {
  # Leer y parsear JSON
  json_config = jsondecode(file("config.json"))
  db_size     = local.json_config.database_size    # "db.t3.medium"

  # Leer y parsear YAML
  yaml_config = yamldecode(file("config.yaml"))
  monitoring  = local.yaml_config.features.monitoring  # true
}
```

---

## Funciones de Path

### `path_relative_to_include()`

**Propósito**: Obtiene el path relativo desde el archivo incluido hasta el actual.

**Uso común**: Organizar el state de Terraform en S3 por estructura de directorios.

**Sintaxis**:
```hcl
path_relative_to_include()
```

**Ejemplo Práctico**:

```hcl
# config/root.hcl
remote_state {
  backend = "s3"
  config = {
    bucket = "my-tfstate"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = "eu-west-1"
  }
}

# Cuando se ejecuta desde: config/eu-west-1/dev/vpc/
# path_relative_to_include() = "eu-west-1/dev/vpc"
# key = "eu-west-1/dev/vpc/terraform.tfstate"
```

**Resultado en S3**:
```
my-tfstate/
├── eu-west-1/dev/vpc/terraform.tfstate
├── eu-west-1/dev/eks/terraform.tfstate
├── eu-west-1/pre/vpc/terraform.tfstate
└── eu-west-1/pro/vpc/terraform.tfstate
```

### `path_relative_from_include()`

**Propósito**: Obtiene el path desde el archivo actual hasta el incluido.

**Sintaxis**:
```hcl
path_relative_from_include()
```

**Ejemplo**:
```hcl
# Si root.hcl está en config/
# Y ejecutas desde config/eu-west-1/dev/vpc/

locals {
  root_path = path_relative_from_include()  # "../../../"
}
```

### `get_terragrunt_dir()`

**Propósito**: Obtiene el directorio donde está el archivo terragrunt.hcl actual.

**Sintaxis**:
```hcl
get_terragrunt_dir()
```

**Ejemplo Práctico**:

```hcl
locals {
  # Path absoluto del directorio actual
  current_dir = get_terragrunt_dir()
  # /home/user/project/config/eu-west-1/dev/vpc

  # Útil para construir paths relativos
  module_path = "${get_terragrunt_dir()}/../../../infra/vpc"
}
```

### `get_parent_terragrunt_dir()`

**Propósito**: Obtiene el directorio del archivo incluido.

**Sintaxis**:
```hcl
get_parent_terragrunt_dir()
```

**Ejemplo**:
```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  # Directorio donde está root.hcl
  root_dir = get_parent_terragrunt_dir()
}
```

---

## Funciones de Dependency

### `dependency` Block

**Propósito**: Declarar dependencias entre módulos y usar sus outputs.

**Sintaxis**:
```hcl
dependency "name" {
  config_path = "path/to/module"

  # Opcional: mock outputs para comandos que no necesitan el state real
  mock_outputs = {
    key = "value"
  }

  # Opcional: permitir outputs mock en comandos específicos
  mock_outputs_allowed_terraform_commands = ["validate", "plan"]

  # Opcional: qué hacer si hay outputs faltantes
  mock_outputs_merge_strategy_with_state = "shallow"
}
```

**Ejemplo Práctico**:

```hcl
# config/eu-west-1/dev/eks/terragrunt.hcl

# Declarar dependencia del módulo VPC
dependency "vpc" {
  config_path = "../vpc"

  # Mock outputs para comandos de validación
  mock_outputs = {
    vpc_id              = "vpc-fake"
    private_subnet_ids  = ["subnet-fake-1", "subnet-fake-2"]
    vpc_cidr            = "10.0.0.0/16"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

# Usar outputs de VPC
inputs = {
  vpc_id             = dependency.vpc.outputs.vpc_id
  subnet_ids         = dependency.vpc.outputs.private_subnet_ids
  vpc_cidr           = dependency.vpc.outputs.vpc_cidr
  cluster_name       = "eks-${dependency.vpc.outputs.environment}"
}
```

**Múltiples Dependencies**:

```hcl
# config/eu-west-1/dev/app/terragrunt.hcl

dependency "vpc" {
  config_path = "../vpc"
}

dependency "eks" {
  config_path = "../eks"
}

dependency "rds" {
  config_path = "../rds"
}

inputs = {
  vpc_id          = dependency.vpc.outputs.vpc_id
  cluster_name    = dependency.eks.outputs.cluster_name
  db_endpoint     = dependency.rds.outputs.endpoint
  db_password     = dependency.rds.outputs.password
}
```

---

## Funciones de Locals

### `locals` Block

**Propósito**: Definir valores locales reutilizables dentro del archivo.

**Sintaxis**:
```hcl
locals {
  key = value
}
```

**Ejemplo Práctico**:

```hcl
locals {
  # Valores básicos
  region      = "eu-west-1"
  environment = "dev"
  project     = "myapp"

  # Valores computados
  name_prefix = "${local.project}-${local.environment}"

  # Listas
  availability_zones = ["${local.region}a", "${local.region}b", "${local.region}c"]

  # Maps
  tags = {
    Environment = local.environment
    Project     = local.project
    ManagedBy   = "Terragrunt"
  }

  # Condicionales
  use_nat_gateway = local.environment == "pro" ? true : false
  instance_count  = local.environment == "pro" ? 3 : 1

  # Combinaciones
  full_name = "${local.name_prefix}-vpc"
}

inputs = {
  name               = local.full_name
  availability_zones = local.availability_zones
  tags               = local.tags
  enable_nat_gateway = local.use_nat_gateway
}
```

---

## Funciones de Terraform

### `terraform` Block

**Propósito**: Configurar cómo Terragrunt ejecuta Terraform.

**Ejemplo Completo**:

```hcl
terraform {
  # Source del módulo
  source = "../../../infra//vpc"

  # Variables extra antes de ejecutar Terraform
  before_hook "validate" {
    commands = ["plan", "apply"]
    execute  = ["echo", "Running Terraform..."]
  }

  # Variables extra después de ejecutar Terraform
  after_hook "notify" {
    commands     = ["apply"]
    execute      = ["./notify-slack.sh", "VPC deployed!"]
    run_on_error = false
  }

  # Variables extra para errores
  error_hook "alert" {
    commands = ["apply", "destroy"]
    execute  = ["./alert.sh", "ERROR"]
  }

  # Variables de entorno para Terraform
  extra_arguments "common_vars" {
    commands = ["plan", "apply", "destroy"]

    arguments = [
      "-var", "region=${local.region}",
      "-var-file=${get_terragrunt_dir()}/extra.tfvars"
    ]

    env_vars = {
      TF_LOG = "DEBUG"
    }
  }
}
```

### `source` - Referencia a Módulos

**Formas de especificar source**:

```hcl
# Path relativo
terraform {
  source = "../../../infra//vpc"
}

# Git con versión
terraform {
  source = "git::https://github.com/myorg/terraform-modules.git//vpc?ref=v1.0.0"
}

# Git con branch
terraform {
  source = "git::https://github.com/myorg/terraform-modules.git//vpc?ref=main"
}

# Terraform Registry
terraform {
  source = "terraform-aws-modules/vpc/aws//."
}

# S3
terraform {
  source = "s3::https://s3.amazonaws.com/mybucket/modules/vpc.zip"
}

# Path local absoluto
terraform {
  source = "/home/user/terraform-modules/vpc"
}
```

---

## Funciones de Environment

### `get_env()`

**Propósito**: Obtener variables de entorno con valor por defecto.

**Sintaxis**:
```hcl
get_env(name, default_value)
```

**Ejemplo Práctico**:

```hcl
locals {
  # Obtener variable de entorno con fallback
  aws_profile = get_env("AWS_PROFILE", "default")
  aws_region  = get_env("AWS_REGION", "eu-west-1")

  # Para debugging
  debug_mode  = get_env("DEBUG", "false") == "true"

  # Para CI/CD
  ci_mode     = get_env("CI", "false") == "true"
  branch      = get_env("BRANCH_NAME", "main")
}

# Usar en remote state
remote_state {
  config = {
    profile = local.aws_profile
    region  = local.aws_region
  }
}

# Usar en inputs
inputs = {
  enable_debugging = local.debug_mode
  deployment_branch = local.branch
}
```

**Uso en CLI**:
```bash
# Ejecutar con variable de entorno
AWS_PROFILE=production terragrunt apply

# Múltiples variables
DEBUG=true AWS_REGION=us-east-1 terragrunt plan
```

---

## Funciones de Comandos

### `run_cmd()`

**Propósito**: Ejecutar comandos shell y usar su output.

**Sintaxis**:
```hcl
run_cmd("command", "arg1", "arg2", ...)
```

**Ejemplo Práctico**:

```hcl
locals {
  # Obtener account ID de AWS
  account_id = run_cmd("aws", "sts", "get-caller-identity", "--query", "Account", "--output", "text")

  # Obtener versión de git
  git_commit = run_cmd("git", "rev-parse", "--short", "HEAD")
  git_branch = run_cmd("git", "rev-parse", "--abbrev-ref", "HEAD")

  # Obtener timestamp
  timestamp = run_cmd("date", "+%Y%m%d-%H%M%S")

  # Comando complejo con pipe
  latest_ami = run_cmd("sh", "-c", "aws ec2 describe-images --owners self --query 'Images[0].ImageId' --output text")
}

inputs = {
  account_id = local.account_id
  tags = {
    GitCommit = local.git_commit
    GitBranch = local.git_branch
    DeployTime = local.timestamp
  }
}
```

**⚠️ Advertencias**:
- El comando se ejecuta cada vez que Terragrunt parsea el archivo
- Puede hacer la ejecución más lenta
- Útil para valores dinámicos, pero usa con moderación

---

## Funciones AWS

### `get_aws_account_id()`

**Propósito**: Obtener el AWS Account ID actual.

**Sintaxis**:
```hcl
get_aws_account_id()
```

**Ejemplo Práctico**:

```hcl
locals {
  account_id = get_aws_account_id()
}

remote_state {
  config = {
    bucket = "tfstate-${local.account_id}"
    role_arn = "arn:aws:iam::${local.account_id}:role/terraform"
  }
}

inputs = {
  kms_key_arn = "arn:aws:kms:eu-west-1:${local.account_id}:key/12345"
}
```

### `get_aws_caller_identity_arn()`

**Propósito**: Obtener el ARN de la identidad actual.

**Sintaxis**:
```hcl
get_aws_caller_identity_arn()
```

**Ejemplo**:
```hcl
locals {
  caller_arn = get_aws_caller_identity_arn()
  # arn:aws:iam::123456789012:user/john
  # o
  # arn:aws:sts::123456789012:assumed-role/MyRole/session-name
}
```

### `get_aws_caller_identity_user_id()`

**Propósito**: Obtener el User ID de la identidad actual.

**Sintaxis**:
```hcl
get_aws_caller_identity_user_id()
```

---

## Funciones de Utilidad

### `get_platform()`

**Propósito**: Detectar el sistema operativo.

**Sintaxis**:
```hcl
get_platform()  # "linux", "darwin", "windows"
```

**Ejemplo Práctico**:

```hcl
locals {
  platform = get_platform()

  # Paths específicos por OS
  terraform_binary = local.platform == "windows" ? "terraform.exe" : "terraform"

  # Scripts específicos por OS
  setup_script = local.platform == "windows" ? "setup.bat" : "./setup.sh"
}
```

### `get_repo_root()`

**Propósito**: Obtener la raíz del repositorio Git.

**Sintaxis**:
```hcl
get_repo_root()
```

**Ejemplo**:
```hcl
locals {
  repo_root = get_repo_root()

  # Construir paths desde la raíz
  shared_config = "${local.repo_root}/shared/config.yaml"
  scripts_dir   = "${local.repo_root}/scripts"
}
```

### `get_terraform_command()`

**Propósito**: Obtener el comando de Terraform que se está ejecutando.

**Sintaxis**:
```hcl
get_terraform_command()  # "plan", "apply", "destroy", etc.
```

**Ejemplo Práctico**:

```hcl
locals {
  command = get_terraform_command()

  # Comportamiento diferente según comando
  auto_approve = local.command == "destroy" ? false : true

  # Mock outputs solo para plan/validate
  use_mocks = contains(["plan", "validate"], local.command)
}
```

### `sops_decrypt_file()`

**Propósito**: Desencriptar archivos con SOPS.

**Sintaxis**:
```hcl
sops_decrypt_file(path)
```

**Ejemplo Práctico**:

```hcl
locals {
  # Desencriptar archivo de secrets
  secrets = yamldecode(sops_decrypt_file("secrets.enc.yaml"))

  # Usar secrets
  db_password     = local.secrets.database.password
  api_key         = local.secrets.api.key
  admin_password  = local.secrets.admin.password
}

inputs = {
  database_password = local.db_password
  api_key          = local.api_key
}
```

---

## Patrones Comunes

### 1. Configuración en Cascada (DRY)

**Propósito**: Evitar repetición usando configuración jerárquica.

```hcl
# config/root.hcl - Nivel global + identidad
# region y environment se derivan del path; account_id y project_name desde account.hcl
locals {
  path_parts   = split("/", path_relative_to_include())
  aws_region   = local.path_parts[0]  # eu-west-1
  environment  = local.path_parts[1]  # dev / pre / pro

  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.aws_account_id
  project_name = local.account_vars.locals.project_name
}

# config/eu-west-1/region.hcl - Nivel región (âncora para localizar _env/)
locals {
  aws_region = basename(get_terragrunt_dir())
}

# config/eu-west-1/_env/common.hcl - Variables de identidad centralizadas
# Se evalúa en contexto del llamador: get_terragrunt_dir() → caller's dir
locals {
  _region        = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  _account       = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  aws_region     = local._region.locals.aws_region
  aws_account_id = local._account.locals.aws_account_id
  project_name   = local._account.locals.project_name
  environment    = basename(dirname(get_terragrunt_dir()))  # "dev" desde .../dev/vpc/
}

# config/eu-west-1/_env/dev.hcl - Config específica del entorno
locals {
  vpc_config = {
    cidr               = "10.0.0.0/16"
    availability_zones = ["eu-west-1a", "eu-west-1b"]
    instance_size      = "t3.small"
  }
}

# config/eu-west-1/dev/vpc/terragrunt.hcl - Nivel módulo
include "root" {
  path = find_in_parent_folders("root.hcl")
}

# include "common" expone identidad (region, env, account, project, tags)
include "common" {
  path           = "${dirname(find_in_parent_folders("region.hcl"))}/_env/common.hcl"
  expose         = true
  merge_strategy = "no_merge"
}

# include "env" expone config específica del entorno
# basename(dirname(get_terragrunt_dir())) → "dev" sin usar local.*
include "env" {
  path           = "${dirname(find_in_parent_folders("region.hcl"))}/_env/${basename(dirname(get_terragrunt_dir()))}.hcl"
  expose         = true
  merge_strategy = "no_merge"
}

inputs = {
  name               = "${include.common.locals.project_name}-${include.common.locals.environment}-vpc"
  availability_zones = include.env.locals.vpc_config.availability_zones
}
```

### 2. Multi-Account Setup

**Propósito**: Gestionar múltiples cuentas AWS.

```hcl
# config/eu-west-1/dev/account.hcl
locals {
  aws_account_id = "123456789012"
  account_name   = "dev"
}

# config/eu-west-1/pre/account.hcl
locals {
  aws_account_id = "210987654321"
  account_name   = "pre"
}

# config/root.hcl
locals {
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.aws_account_id
  account_name = local.account_vars.locals.account_name
}

remote_state {
  backend = "s3"
  config = {
    bucket = "tfstate-${local.account_id}"
    key    = "${path_relative_to_include()}/terraform.tfstate"
    region = "eu-west-1"

    assume_role = {
      role_arn = "arn:aws:iam::${local.account_id}:role/terraform"
    }
  }
}
```

### 3. Entornos con Configuración Diferente

**Propósito**: Valores diferentes por entorno.

```hcl
# config/_envs/common.hcl
locals {
  # Configuración común
  project = "myapp"
  region  = "eu-west-1"

  # Configuración específica por entorno
  env_config = {
    dev = {
      instance_type = "t3.small"
      min_size      = 1
      max_size      = 3
      multi_az      = false
    }
    pre = {
      instance_type = "t3.medium"
      min_size      = 2
      max_size      = 6
      multi_az      = true
    }
    pro = {
      instance_type = "t3.large"
      min_size      = 3
      max_size      = 10
      multi_az      = true
    }
  }
}

# config/eu-west-1/dev/terragrunt.hcl
locals {
  common = read_terragrunt_config(find_in_parent_folders("common.hcl"))
  env    = "dev"
  config = local.common.locals.env_config[local.env]
}

inputs = {
  instance_type = local.config.instance_type
  min_size      = local.config.min_size
  max_size      = local.config.max_size
  multi_az      = local.config.multi_az
}
```

### 4. Feature Flags

**Propósito**: Habilitar/deshabilitar features por entorno.

```hcl
# config/_features/features.hcl
locals {
  features = {
    dev = {
      monitoring       = true
      backup           = false
      multi_az         = false
      cloudwatch_logs  = true
      cost_optimization = false
    }
    pre = {
      monitoring       = true
      backup           = true
      multi_az         = true
      cloudwatch_logs  = true
      cost_optimization = false
    }
    pro = {
      monitoring       = true
      backup           = true
      multi_az         = true
      cloudwatch_logs  = true
      cost_optimization = true
    }
  }
}

# config/eu-west-1/dev/terragrunt.hcl
locals {
  features_config = read_terragrunt_config(find_in_parent_folders("features.hcl"))
  env             = "dev"
  features        = local.features_config.locals.features[local.env]
}

inputs = {
  enable_monitoring      = local.features.monitoring
  enable_backup          = local.features.backup
  enable_multi_az        = local.features.multi_az
  enable_cloudwatch_logs = local.features.cloudwatch_logs
}
```

### 5. Dynamic Backend Configuration

**Propósito**: Backend diferente según el entorno.

```hcl
locals {
  # Entorno derivado del path: eu-west-1/dev/vpc → path_parts[1] = "dev"
  path_parts = split("/", path_relative_to_include())
  env        = local.path_parts[1]

  # Backend config por entorno
  backend_config = {
    dev = {
      bucket         = "tfstate-dev"
      dynamodb_table = "tfstate-lock-dev"
      encrypt        = true
    }
    pro = {
      bucket         = "tfstate-pro"
      dynamodb_table = "tfstate-lock-pro"
      encrypt        = true
      kms_key_id     = "arn:aws:kms:eu-west-1:123456:key/xyz"
    }
  }

  backend = local.backend_config[local.env]
}

remote_state {
  backend = "s3"
  config  = merge(
    local.backend,
    {
      key    = "${path_relative_to_include()}/terraform.tfstate"
      region = "eu-west-1"
    }
  )
}
```

---

## Ejemplos Completos

### Ejemplo 1: Configuración Multi-Región, Multi-Cuenta

```hcl
# config/root.hcl
#
# Estructura esperada: {region}/{env}/{component}
# Ejemplo: eu-west-1/dev/vpc
#
# - region y environment: derivados de path_relative_to_include()
# - account_id y project_name: leídos desde account.hcl (uno por entorno)
locals {
  path_parts   = split("/", path_relative_to_include())
  aws_region   = local.path_parts[0]  # eu-west-1
  environment  = local.path_parts[1]  # dev / pre / pro

  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.aws_account_id
  project_name = local.account_vars.locals.project_name
}

# Backend S3 con S3 native locking
remote_state {
  backend = "s3"
  config = {
    bucket         = "${local.project_name}-tfstate-${local.environment}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
    encrypt        = true
    use_lockfile   = true

    profile = "devops"

    assume_role = {
      role_arn     = "arn:aws:iam::${local.account_id}:role/tfadmin"
      session_name = "terragrunt-backend-${local.environment}"
    }
  }

  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Provider generation
generate "provider" {
  path      = "_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region  = "${local.aws_region}"
      profile = "devops"

      assume_role {
        role_arn     = "arn:aws:iam::${local.account_id}:role/tfadmin"
        session_name = "terragrunt-${local.environment}"
      }

      default_tags {
        tags = {
          Environment = "${local.environment}"
          Project     = "${local.project_name}"
          ManagedBy   = "Terragrunt"
        }
      }
    }
  EOF
}

# Inputs comunes para todos los módulos
inputs = {
  environment  = local.environment
  project_name = local.project_name
  aws_region   = local.aws_region

  tags = {
    Environment = local.environment
    Project     = local.project_name
    ManagedBy   = "Terragrunt"
  }
}
```

### Ejemplo 2: VPC con Dependencies

```hcl
# config/eu-west-1/dev/vpc/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git///?ref=v5.0.0"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals.env

  # CIDR blocks por entorno
  cidr_blocks = {
    dev = "10.0.0.0/16"
    pre = "10.10.0.0/16"
    pro = "10.20.0.0/16"
  }
}

inputs = {
  name = "myapp-${local.env}-vpc"
  cidr = local.cidr_blocks[local.env]

  azs             = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false
  enable_dns_hostnames = true
  enable_dns_support   = true
}
```

```hcl
# config/eu-west-1/dev/eks/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git///?ref=v19.0.0"
}

# Dependencia de VPC
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id              = "vpc-mock"
    private_subnet_ids  = ["subnet-mock-1", "subnet-mock-2"]
    vpc_cidr_block      = "10.0.0.0/16"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals.env

  # Configuración de cluster por entorno
  cluster_config = {
    dev = {
      version        = "1.27"
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
    }
    pro = {
      version        = "1.27"
      instance_types = ["t3.large"]
      desired_size   = 3
      min_size       = 3
      max_size       = 10
    }
  }

  config = local.cluster_config[local.env]
}

inputs = {
  cluster_name    = "myapp-${local.env}-eks"
  cluster_version = local.config.version

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnet_ids

  eks_managed_node_groups = {
    main = {
      instance_types = local.config.instance_types
      min_size       = local.config.min_size
      max_size       = local.config.max_size
      desired_size   = local.config.desired_size
    }
  }

  # Security group rules basadas en VPC CIDR
  cluster_security_group_additional_rules = {
    ingress_vpc = {
      description = "Allow from VPC"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = [dependency.vpc.outputs.vpc_cidr_block]
    }
  }
}
```

### Ejemplo 3: RDS con Secrets de SOPS

```hcl
# config/eu-west-1/dev/rds/terragrunt.hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git///?ref=v6.0.0"
}

dependency "vpc" {
  config_path = "../vpc"
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals.env

  # Desencriptar secrets con SOPS
  secrets = yamldecode(sops_decrypt_file("${get_terragrunt_dir()}/secrets.enc.yaml"))

  # RDS config por entorno
  rds_config = {
    dev = {
      instance_class    = "db.t3.micro"
      allocated_storage = 20
      multi_az          = false
      backup_retention  = 7
    }
    pro = {
      instance_class    = "db.r5.large"
      allocated_storage = 100
      multi_az          = true
      backup_retention  = 30
    }
  }

  config = local.rds_config[local.env]
}

inputs = {
  identifier = "myapp-${local.env}-db"

  engine               = "postgres"
  engine_version       = "14.7"
  family               = "postgres14"
  major_engine_version = "14"
  instance_class       = local.config.instance_class

  allocated_storage     = local.config.allocated_storage
  max_allocated_storage = local.config.allocated_storage * 2

  db_name  = "myapp"
  username = "admin"
  password = local.secrets.database.password

  multi_az               = local.config.multi_az
  db_subnet_group_name   = dependency.vpc.outputs.database_subnet_group
  vpc_security_group_ids = [dependency.vpc.outputs.database_security_group_id]

  backup_retention_period = local.config.backup_retention
  backup_window           = "03:00-06:00"
  maintenance_window      = "Mon:00:00-Mon:03:00"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  deletion_protection = local.env == "pro" ? true : false
  skip_final_snapshot = local.env == "dev" ? true : false
}
```

---

## Best Practices

### 1. Usa `find_in_parent_folders()` para DRY

✅ **Bueno**:
```hcl
include "root" {
  path = find_in_parent_folders("root.hcl")
}
```

❌ **Malo**:
```hcl
include "root" {
  path = "../../../root.hcl"  # Frágil si cambias estructura
}
```

### 2. Usa Mock Outputs para Validación

✅ **Bueno**:
```hcl
dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-mock"
  }

  mock_outputs_allowed_terraform_commands = ["validate", "plan"]
}
```

### 3. Centraliza Configuración

✅ **Bueno** - Configuración jerárquica:
```
config/
├── root.hcl          # Global
└── region/
    ├── region.hcl    # Por región
    └── env/
        ├── env.hcl   # Por entorno
        └── module/
```

### 4. Usa Locals para Valores Computados

✅ **Bueno**:
```hcl
locals {
  name = "${local.project}-${local.env}-vpc"
}

inputs = {
  name = local.name
}
```

### 5. Documenta Funciones Complejas

```hcl
locals {
  # Obtiene el account ID desde la configuración jerárquica
  # Busca account.hcl subiendo en el árbol de directorios
  account_vars = read_terragrunt_config(find_in_parent_folders("account.hcl"))
  account_id   = local.account_vars.locals.aws_account_id
}
```

---

## Referencias

- **Documentación oficial**: https://terragrunt.gruntwork.io/docs/reference/built-in-functions/
- **Ejemplos**: https://github.com/gruntwork-io/terragrunt-infrastructure-live-example

---

**Versión del documento**: Compatible con Terragrunt v0.89.4
**Última actualización**: 2026-02-25
