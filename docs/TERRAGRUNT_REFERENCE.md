# Guía Completa de Terragrunt v0.89.4

Esta guía cubre los comandos modernos de Terragrunt v0.89.4, que ha cambiado significativamente respecto a versiones anteriores.

## Tabla de Contenidos

- [Cambios Importantes en v0.89+](#cambios-importantes-en-v089)
- [Comandos Principales](#comandos-principales)
- [Comando `run`](#comando-run)
- [Comando `stack`](#comando-stack)
- [Comandos de Descubrimiento](#comandos-de-descubrimiento)
- [Comandos de Configuración](#comandos-de-configuración)
- [Opciones Globales Importantes](#opciones-globales-importantes)
- [Ejemplos Prácticos](#ejemplos-prácticos)

---

## Cambios Importantes en v0.89+

### ❌ **DEPRECATED**: `run-all` (versiones antiguas)
```bash
# ❌ ANTIGUO (no usar más)
terragrunt run-all plan
terragrunt run-all apply
```

### ✅ **NUEVO**: `run --all` o shortcut directo
```bash
# ✅ NUEVO - Forma explícita
terragrunt run --all -- plan
terragrunt run --all -- apply

# ✅ NUEVO - Shortcut (recomendado)
terragrunt plan --all
terragrunt apply --all
```

### Nuevo Modelo de Comandos

Terragrunt ahora tiene una estructura más clara:
- **`run`**: Ejecuta comandos de Terraform/OpenTofu
- **`stack`**: Gestión de stacks completos
- **`backend`**: Operaciones de backend
- **`exec`**: Comandos arbitrarios

---

## Comandos Principales

### 1. `run` - Ejecutar Comandos Terraform/OpenTofu

Forma principal de ejecutar comandos de IaC.

```bash
# Forma explícita
terragrunt run -- <comando>

# Shortcuts disponibles (recomendados)
terragrunt plan
terragrunt apply
terragrunt destroy
terragrunt init
terragrunt output
terragrunt validate
```

#### Opciones Importantes del Comando `run`

| Opción | Descripción | Ejemplo |
|--------|-------------|---------|
| `--all, -a` | Ejecuta en todas las unidades del stack | `terragrunt plan --all` |
| `--graph` | Sigue el DAG de dependencias | `terragrunt apply --graph` |
| `--parallelism <n>` | Limita ejecución paralela | `terragrunt apply --all --parallelism 5` |
| `--fail-fast` | Para todo si una unidad falla | `terragrunt apply --all --fail-fast` |
| `--no-auto-init` | No ejecuta init automáticamente | `terragrunt plan --no-auto-init` |
| `--no-auto-approve` | No añade auto-approve a apply/destroy | `terragrunt destroy --all --no-auto-approve` |

---

## Comando `run` en Detalle

### Ejecución en un Solo Módulo

```bash
# En el directorio de un módulo
cd config/eu-west-1/dev/vpc

# Inicializar
terragrunt init

# Planificar
terragrunt plan

# Aplicar
terragrunt apply

# Ver outputs
terragrunt output

# Destruir
terragrunt destroy
```

### Ejecución en Todo el Stack

```bash
# Desde el directorio raíz o cualquier nivel
cd config/eu-west-1

# Planificar todo
terragrunt plan --all

# Aplicar todo (con confirmación)
terragrunt apply --all

# Aplicar todo (sin confirmación - CI/CD)
terragrunt apply --all --non-interactive

# Destruir todo
terragrunt destroy --all
```

### Control de Dependencias

```bash
# Ejecutar siguiendo el grafo de dependencias
terragrunt apply --graph

# Ejecutar todo sin importar dependencias (peligroso)
terragrunt apply --all --queue-ignore-dag-order

# Ignorar errores y continuar
terragrunt apply --all --queue-ignore-errors
```

### Filtrado de Módulos

```bash
# Solo módulos en un directorio específico
terragrunt plan --all --queue-include-dir "dev/*"

# Excluir directorios
terragrunt apply --all --queue-exclude-dir "test/*"

# Solo módulos que incluyen un archivo específico
terragrunt plan --all --queue-include-units-reading "common.hcl"
```

---

## Comando `stack`

El comando `stack` es una nueva característica para gestión declarativa de infraestructura completa.

### Subcomandos de Stack

```bash
# Generar un stack desde terragrunt.stack.hcl
terragrunt stack generate

# Ejecutar comando en el stack
terragrunt stack run -- plan

# Obtener outputs del stack
terragrunt stack output

# Limpiar archivos generados del stack
terragrunt stack clean
```

### Ejemplo de Stack

Crea un archivo `terragrunt.stack.hcl`:

```hcl
stack {
  name = "infrastructure"

  units = [
    {
      name = "vpc"
      path = "./vpc"
    },
    {
      name = "eks"
      path = "./eks"
      dependencies = ["vpc"]
    }
  ]
}
```

Luego ejecuta:

```bash
# Generar el stack
terragrunt stack generate

# Ejecutar plan en todo el stack
terragrunt stack run -- plan

# Aplicar el stack completo
terragrunt stack run -- apply
```

---

## Comandos de Descubrimiento

### `find` / `fd` - Buscar Configuraciones

```bash
# Buscar todos los terragrunt.hcl
terragrunt find

# Con filtros
terragrunt find --filter "*.hcl"
```

### `list` / `ls` - Listar Configuraciones

```bash
# Listar todas las unidades de Terragrunt
terragrunt list

# Listar con información detallada
terragrunt list --verbose
```

---

## Comandos de Configuración

### `dag` - Grafo de Dependencias

```bash
# Generar y visualizar el DAG
terragrunt dag

# Guardar en archivo
terragrunt dag > dependencies.dot

# Convertir a imagen (requiere graphviz)
terragrunt dag | dot -Tpng > dependencies.png
```

### `hcl` - Interacción con HCL

```bash
# Validar sintaxis HCL
terragrunt hcl validate

# Ver configuración parseada
terragrunt hcl eval
```

### `render` - Renderizar Configuración

```bash
# Renderizar configuración final
terragrunt render

# Renderizar en formato JSON
terragrunt render --format json

# Renderizar en formato HCL
terragrunt render --format hcl
```

### `info` - Información de Configuración

```bash
# Ver información general
terragrunt info

# Ver controles de strict mode
terragrunt info strict
```

---

## Comandos de Backend

```bash
# Ver información del backend
terragrunt backend info

# Inicializar backend
terragrunt backend init
```

---

## Comando `exec`

Ejecuta comandos arbitrarios con el contexto de Terragrunt.

```bash
# Ejecutar un script personalizado
terragrunt exec -- ./custom-script.sh

# Ejecutar comando shell
terragrunt exec -- bash -c "echo \$AWS_PROFILE"
```

---

## Comandos de Catalog

Nuevas características para gestión de módulos.

```bash
# Lanzar UI para buscar módulos
terragrunt catalog

# Crear scaffold de nuevo módulo
terragrunt scaffold <module-name>
```

---

## Opciones Globales Importantes

### Logging y Debug

```bash
# Nivel de log (trace, debug, info, warn, error)
terragrunt --log-level debug plan

# Sin color (para CI/CD)
terragrunt --no-color apply --all

# Desactivar logs
terragrunt --log-disable apply

# Mostrar paths absolutos
terragrunt --log-show-abs-paths plan
```

### Directorio de Trabajo

```bash
# Especificar directorio de trabajo
terragrunt --working-dir /path/to/config plan

# Cambiar download dir (caché)
terragrunt --download-dir /tmp/tg-cache init
```

### Modo Interactivo

```bash
# No pedir confirmación (útil en CI/CD)
terragrunt --non-interactive apply --all

# Modo estricto
terragrunt --strict-mode plan
```

### Experimentos

```bash
# Habilitar modo experimental
terragrunt --experiment-mode plan

# Habilitar experimento específico
terragrunt --experiment provider_cache apply
```

---

## Ejemplos Prácticos

### 1. Despliegue Inicial Completo

```bash
# Desde el directorio raíz
cd config/eu-west-1

# Inicializar todos los módulos
terragrunt init --all

# Planificar todo el stack
terragrunt plan --all

# Aplicar con confirmación
terragrunt apply --all

# Ver todos los outputs
terragrunt output --all
```

### 2. Despliegue Solo de DEV

```bash
cd config/eu-west-1

# Solo módulos en dev/
terragrunt apply --all \
  --queue-include-dir "dev/*"
```

### 3. Actualizar Solo VPC en Todos los Entornos

```bash
cd config/eu-west-1

# Solo directorios vpc/
terragrunt apply --all \
  --queue-include-dir "*/vpc"
```

### 4. Destruir Todo PRE (Entorno Completo)

```bash
cd config/eu-west-1

# Destruir solo PRE
terragrunt destroy --all \
  --queue-include-dir "pre/*"
```

### 5. Plan con Máximo Paralelismo

```bash
# Ejecutar con 10 workers paralelos
terragrunt plan --all --parallelism 10
```

### 6. Debugging de Dependencias

```bash
# Ver el DAG de dependencias
terragrunt dag

# Ver configuración renderizada
terragrunt render --format json | jq .

# Listar todas las unidades
terragrunt list
```

### 7. CI/CD Pipeline

```bash
# En CI/CD usa estas flags
terragrunt plan --all \
  --non-interactive \
  --no-color \
  --log-level info

terragrunt apply --all \
  --non-interactive \
  --no-color \
  --fail-fast
```

### 8. Verificar Estado del Backend

```bash
# Ver información del backend
terragrunt backend info

# En cada módulo
cd config/eu-west-1/dev/vpc
terragrunt backend info
```

### 9. Provider Caching (Acelerar Ejecución)

```bash
# Habilitar cache de providers
terragrunt init --all \
  --provider-cache \
  --provider-cache-dir ~/.terragrunt/cache

# O con variable de entorno
export TG_PROVIDER_CACHE=true
export TG_PROVIDER_CACHE_DIR=~/.terragrunt/cache
terragrunt init --all
```

### 10. Limpieza de Caché

```bash
# Limpiar caché de un módulo
rm -rf .terragrunt-cache

# Limpiar caché de todos los módulos
find . -name ".terragrunt-cache" -type d -exec rm -rf {} +

# Re-inicializar con source update
terragrunt init --source-update
```

---

## Estructura de Proyecto Recomendada

```
project/
├── config/
│   ├── root.hcl                    # Configuración global
│   └── eu-west-1/
│       ├── region.hcl              # Configuración regional
│       ├── dev/
│       │   ├── account.hcl         # Config de cuenta
│       │   ├── env.hcl             # Config de entorno
│       │   └── vpc/
│       │       └── terragrunt.hcl  # Config del módulo
│       ├── pre/
│       │   ├── account.hcl
│       │   ├── env.hcl
│       │   └── vpc/
│       │       └── terragrunt.hcl
│       └── pro/
│           ├── account.hcl
│           ├── env.hcl
│           └── vpc/
│               └── terragrunt.hcl
└── infra/
    └── vpc/                        # Módulo Terraform
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Comandos Equivalentes: Antiguo vs Nuevo

| Antiguo (deprecated) | Nuevo (v0.89+) | Shortcut |
|---------------------|----------------|----------|
| `terragrunt run-all plan` | `terragrunt run --all -- plan` | `terragrunt plan --all` |
| `terragrunt run-all apply` | `terragrunt run --all -- apply` | `terragrunt apply --all` |
| `terragrunt run-all destroy` | `terragrunt run --all -- destroy` | `terragrunt destroy --all` |
| `terragrunt run-all output` | `terragrunt run --all -- output` | `terragrunt output --all` |
| `terragrunt run-all init` | `terragrunt run --all -- init` | `terragrunt init --all` |
| `terragrunt plan-all` | `terragrunt run --all -- plan` | `terragrunt plan --all` |
| `terragrunt apply-all` | `terragrunt run --all -- apply` | `terragrunt apply --all` |

---

## Variables de Entorno Útiles

```bash
# Deshabilitar auto-init
export TG_NO_AUTO_INIT=true

# Nivel de log
export TG_LOG_LEVEL=debug

# Directorio de trabajo
export TG_WORKING_DIR=/path/to/config

# Non-interactive
export TG_NON_INTERACTIVE=true

# Paralelismo
export TG_PARALLELISM=10

# Provider cache
export TG_PROVIDER_CACHE=true
export TG_PROVIDER_CACHE_DIR=~/.terragrunt/cache

# Path de terraform/tofu
export TG_TF_PATH=/usr/local/bin/tofu
```

---

## Tips y Best Practices

### 1. Usa Shortcuts
```bash
# ✅ Mejor - más corto y claro
terragrunt plan --all

# ❌ Más verboso
terragrunt run --all -- plan
```

### 2. Provider Caching en Desarrollo
```bash
# Acelera init en desarrollo local
export TG_PROVIDER_CACHE=true
terragrunt init --all
```

### 3. Visualiza Dependencias
```bash
# Antes de apply, verifica el orden
terragrunt dag | dot -Tpng > graph.png
open graph.png
```

### 4. Plan Antes de Apply
```bash
# Siempre haz plan primero
terragrunt plan --all | tee plan.log

# Revisa, luego aplica
terragrunt apply --all
```

### 5. Usa Filtros en Stacks Grandes
```bash
# Solo cambios en un entorno
terragrunt plan --all --queue-include-dir "dev/*"

# Excluye tests
terragrunt apply --all --queue-exclude-dir "test/*"
```

### 6. Fail-Fast en Producción
```bash
# Para inmediatamente si algo falla
terragrunt apply --all --fail-fast
```

### 7. Debugging
```bash
# Máximo detalle
terragrunt --log-level trace \
  --log-show-abs-paths \
  plan --all
```

---

## Solución de Problemas

### Problema: "Error assuming role"

```bash
# Verifica que el profile funciona
aws sts get-caller-identity --profile devops

# Verifica que puedes asumir el role
aws sts assume-role \
  --role-arn arn:aws:iam::ACCOUNT_ID:role/tfadmin \
  --role-session-name test \
  --profile devops
```

### Problema: "State bucket does not exist"

```bash
# Verifica que el bucket existe
aws s3 ls s3://bucket-name --profile devops

# Si no existe, créalo con el script
./create-state-buckets-pre-pro.sh
```

### Problema: Caché corrupta

```bash
# Limpia la caché
rm -rf .terragrunt-cache

# Re-inicializa
terragrunt init --source-update
```

### Problema: Dependencias no resueltas

```bash
# Visualiza el DAG
terragrunt dag

# Fuerza regeneración
terragrunt init --all --source-update
```

---

## Referencias

- **Documentación oficial**: https://terragrunt.gruntwork.io/
- **Changelog v0.89+**: https://github.com/gruntwork-io/terragrunt/releases
- **GitHub**: https://github.com/gruntwork-io/terragrunt
- **Experiment Mode**: https://terragrunt.gruntwork.io/docs/reference/experiment-mode

---

## Changelog Importantes

### v0.89.x
- ✅ Introducción de `run --all` (reemplaza `run-all`)
- ✅ Nuevo comando `stack`
- ✅ Comandos `find` y `list` para descubrimiento
- ✅ Mejor manejo de provider caching
- ✅ Opciones de queue más granulares

### Deprecations
- ❌ `run-all` (usa `run --all`)
- ❌ `plan-all` (usa `plan --all`)
- ❌ `apply-all` (usa `apply --all`)
- ❌ `destroy-all` (usa `destroy --all`)

---

**Versión del documento**: Compatible con Terragrunt v0.89.4
**Última actualización**: 2026-02-25
