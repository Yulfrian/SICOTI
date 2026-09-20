#!/usr/bin/env bash
set -euo pipefail

OWNER="Yulfrian"
PROJECT_NUMBER=2
REPO="Yulfrian/SICOTI"

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) no está instalado o no está en PATH."
  echo "Instálalo y ejecuta: gh auth login"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "No estás autenticado en GitHub CLI. Ejecuta: gh auth login"
  exit 1
fi

FIELDS_JSON="$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json)"
PROJECT_ID="$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json | jq -r '.id')"

field_id() {
  local field_name="$1"
  echo "$FIELDS_JSON" | jq -r --arg name "$field_name" '.fields[] | select(.name == $name) | .id' | head -n 1
}

option_id() {
  local field_name="$1"
  local option_name="$2"
  echo "$FIELDS_JSON" | jq -r --arg field "$field_name" --arg option "$option_name" '
    .fields[]
    | select(.name == $field)
    | .options[]
    | select(.name == $option)
    | .id
  ' | head -n 1
}

ensure_single_select_field() {
  local field_name="$1"
  local options_csv="$2"
  local field_id_value
  field_id_value="$(field_id "$field_name")"

  if [[ -z "$field_id_value" || "$field_id_value" == "null" ]]; then
    echo "Creando campo: $field_name"
    gh project field-create "$PROJECT_NUMBER" \
      --owner "$OWNER" \
      --title "$field_name" \
      --data-type "SINGLE_SELECT" \
      --single-select-options "$options_csv" >/dev/null
    FIELDS_JSON="$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --format json)"
  else
    echo "Campo existente: $field_name"
  fi
}

ensure_single_select_field "Tipo" "Arquitectura,Modelado,Interfaz,Requisito,Ajustes,Pruebas"
ensure_single_select_field "Prioridad" "Alta,Media,Baja"
ensure_single_select_field "Responsable (Rol)" "Apoyo Técnico,Responsable de Modelado,Analista,Responsable del Tablero,Resp. de Documentación"
ensure_single_select_field "Status" "Backlog,Por hacer,En progreso,En revisión,Finalizado"
ensure_single_select_field "Fecha Estimada" "2026-09-20,2026-09-22,2026-09-24,2026-09-26,2026-09-28,2026-09-30,2026-10-02,2026-10-04,2026-10-10,2026-10-15"

# NOTA: "Fecha Estimada" en Project V2 no debe ser un SINGLE_SELECT si se quiere usar una fecha real.
# En una configuración ideal, este campo debe configurarse como DATE. Si quieres dejarlo como DATE,
# elimina esa línea anterior y usa `gh project field-create ... --data-type DATE` para este campo.

TYPE_FIELD_ID="$(field_id "Tipo")"
PRIORITY_FIELD_ID="$(field_id "Prioridad")"
ROLE_FIELD_ID="$(field_id "Responsable (Rol)")"
STATUS_FIELD_ID="$(field_id "Status")"
DATE_FIELD_ID="$(field_id "Fecha Estimada")"

if [[ -z "$TYPE_FIELD_ID" || "$TYPE_FIELD_ID" == "null" ]]; then
  echo "Falta el campo Tipo. Revisa la configuración del proyecto."
  exit 1
fi
if [[ -z "$PRIORITY_FIELD_ID" || "$PRIORITY_FIELD_ID" == "null" ]]; then
  echo "Falta el campo Prioridad. Revisa la configuración del proyecto."
  exit 1
fi
if [[ -z "$ROLE_FIELD_ID" || "$ROLE_FIELD_ID" == "null" ]]; then
  echo "Falta el campo Responsable (Rol). Revisa la configuración del proyecto."
  exit 1
fi
if [[ -z "$STATUS_FIELD_ID" || "$STATUS_FIELD_ID" == "null" ]]; then
  echo "Falta el campo Status. Revisa la configuración del proyecto."
  exit 1
fi
if [[ -z "$DATE_FIELD_ID" || "$DATE_FIELD_ID" == "null" ]]; then
  echo "Falta el campo Fecha Estimada. Revisa la configuración del proyecto."
  exit 1
fi

create_card() {
  local title="$1"
  local type="$2"
  local priority="$3"
  local role="$4"
  local date_iso="$5"
  local status="$6"

  local body
  body=$(cat <<EOF
## Detalle
- Tipo: $type
- Prioridad: $priority
- Responsable (Rol): $role
- Fecha Estimada: $date_iso
- Estado del tablero: $status

## Objetivo
Implementar esta actividad técnica dentro del sistema SICOTI.
EOF
)

  local issue_json issue_url item_id type_opt priority_opt role_opt status_opt

  echo "Creando issue: $title"
  issue_json="$(gh issue create --repo "$REPO" --title "$title" --body "$body" --label "SICOTI" --json number,url)"
  issue_url="$(echo "$issue_json" | jq -r '.url')"

  gh project item-add --owner "$OWNER" --project-id "$PROJECT_ID" --url "$issue_url" >/dev/null

  item_id="$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --format json | jq -r --arg url "$issue_url" '.items[] | select(.content.url == $url) | .id' | head -n 1)"

  if [[ -z "$item_id" || "$item_id" == "null" ]]; then
    echo "No se pudo localizar el item del proyecto para: $title"
    exit 1
  fi

  type_opt="$(option_id "Tipo" "$type")"
  priority_opt="$(option_id "Prioridad" "$priority")"
  role_opt="$(option_id "Responsable (Rol)" "$role")"
  status_opt="$(option_id "Status" "$status")"

  gh project item-edit \
    --id "$item_id" \
    --project-id "$PROJECT_ID" \
    --field-id "$TYPE_FIELD_ID" \
    --single-select-option-id "$type_opt" >/dev/null

  gh project item-edit \
    --id "$item_id" \
    --project-id "$PROJECT_ID" \
    --field-id "$PRIORITY_FIELD_ID" \
    --single-select-option-id "$priority_opt" >/dev/null

  gh project item-edit \
    --id "$item_id" \
    --project-id "$PROJECT_ID" \
    --field-id "$ROLE_FIELD_ID" \
    --single-select-option-id "$role_opt" >/dev/null

  gh project item-edit \
    --id "$item_id" \
    --project-id "$PROJECT_ID" \
    --field-id "$STATUS_FIELD_ID" \
    --single-select-option-id "$status_opt" >/dev/null

  # Si el campo Fecha Estimada está definido como DATE, usar esta línea en lugar de la de SINGLE_SELECT
  gh project item-edit \
    --id "$item_id" \
    --project-id "$PROJECT_ID" \
    --field-id "$DATE_FIELD_ID" \
    --date "$date_iso" >/dev/null

  echo "Issue creado y ubicado en $status: $issue_url"
  echo
}

create_card "Configuración del Repositorio y Entorno" "Arquitectura" "Alta" "Apoyo Técnico" "2026-09-20" "Finalizado"
create_card "Diseño de la Base de Datos (MySQL 8.0)" "Modelado" "Alta" "Responsable de Modelado" "2026-09-22" "Finalizado"
create_card "Definición de arquitectura cliente-servidor" "Arquitectura" "Alta" "Responsable de Modelado" "2026-09-24" "En revisión"
create_card "Integración de la Interfaz UI/UX (React.js)" "Interfaz" "Media" "Apoyo Técnico" "2026-09-26" "En progreso"
create_card "Programar sistema de alertas de stock mínimo" "Requisito" "Alta" "Analista" "2026-09-28" "En progreso"
create_card "Desarrollar vista de inventario en tiempo real" "Requisito" "Alta" "Analista" "2026-09-30" "En progreso"
create_card "Crear módulo de mermas y devoluciones" "Requisito" "Media" "Responsable del Tablero" "2026-10-02" "Por hacer"
create_card "Implementar filtros por categoría en catálogo" "Interfaz" "Baja" "Resp. de Documentación" "2026-10-04" "Por hacer"
create_card "Integración de escáner de código de barras en POS" "Ajustes" "Alta" "Apoyo Técnico" "2026-10-10" "Backlog"
create_card "Pruebas de latencia y rendimiento de la API REST" "Pruebas" "Alta" "Analista" "2026-10-15" "Backlog"

echo "Proceso finalizado. Comprueba la vista del proyecto: https://github.com/users/Yulfrian/projects/2/views/1"
