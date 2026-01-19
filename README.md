# Tech Playground - Employee Feedback Analytics

Sistema de análise de dados de feedback de funcionários desenvolvido com Ruby on Rails.

## Tecnologias

| Tecnologia | Versão |
|------------|--------|
| Ruby | 3.3.10 |
| Rails | 8.1.2 |
| PostgreSQL | 16 |
| Docker | Latest |
| Tailwind CSS | 4.x |

### Gems Principais

- **chartkick** + **groupdate** - Visualizações e gráficos
- **pagy** - Paginação
- **view_component** - Componentes reutilizáveis
- **rack-cors** - Suporte a CORS
- **rack-attack** - Rate limiting
- **rspec-rails** - Testes

---

## Instalação e Execução

### Pré-requisitos

- Docker e Docker Compose instalados

### 1. Clone o repositório

```bash
git clone <repo-url>
cd tech_playground
```

### 2. Suba os containers

```bash
docker-compose up --build
```

Isso irá:
- Subir o banco de dados PostgreSQL (porta 5432)
- Subir a aplicação Rails (porta 3000)
- Executar migrations automaticamente
- Compilar Tailwind CSS

### 3. Importe os dados do CSV

```bash
docker-compose exec web bundle exec rake data:import
```

### 4. Acesse a aplicação

- **Dashboard**: http://localhost:3000
- **API**: http://localhost:3000/api/v1
- **Health Check**: http://localhost:3000/up

---

## Comandos Úteis

### Docker

```bash
# Subir containers
docker-compose up

# Subir containers em background
docker-compose up -d

# Parar containers
docker-compose down

# Ver logs
docker-compose logs -f web

# Rebuild containers
docker-compose up --build

# Limpar volumes (apaga banco de dados)
docker-compose down -v
```

### Rails (dentro do container)

```bash
# Console Rails
docker-compose exec web bundle exec rails console

# Executar migrations
docker-compose exec web bundle exec rails db:migrate

# Importar dados do CSV
docker-compose exec web bundle exec rake data:import

# Ver todas as rake tasks
docker-compose exec web bundle exec rake -T
```

### Testes

```bash
# Executar todos os testes
docker-compose --profile test run test

# Ou execute diretamente
docker-compose exec web bundle exec rspec
```

---

## API Endpoints

Base URL: `http://localhost:3000/api/v1`

### Employees

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/employees` | Lista todos os funcionários |
| GET | `/employees/:id` | Detalhes de um funcionário |
| GET | `/employees/:id/responses` | Respostas de um funcionário |

### Responses

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/responses` | Lista todas as respostas |

### Imports

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/imports` | Lista importações |
| GET | `/imports/:id` | Detalhes de uma importação |
| POST | `/imports` | Criar nova importação |

### Analytics - Dashboard

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/analytics/dashboard` | Overview completo |
| GET | `/analytics/dashboard/executive` | Resumo executivo |
| GET | `/analytics/dashboard/departments` | Métricas por departamento |
| GET | `/analytics/dashboard/trends` | Tendências |
| GET | `/analytics/dashboard/alerts` | Alertas |

### Analytics - Favorability

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/analytics/favorability` | Análise de favorabilidade |
| GET | `/analytics/favorability/by_department` | Por departamento |
| GET | `/analytics/favorability/by_location` | Por localidade |

### Analytics - NPS

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/analytics/nps` | Análise de eNPS |
| GET | `/analytics/nps/distribution` | Distribuição (promoters/passives/detractors) |
| GET | `/analytics/nps/trend` | Tendência temporal |
| GET | `/analytics/nps/by_department` | Por departamento |
| GET | `/analytics/nps/by_location` | Por localidade |
| GET | `/analytics/nps/at_risk` | Departamentos em risco |

### Filtros Disponíveis

Parâmetros de query suportados:
- `department` - Filtrar por departamento
- `location` - Filtrar por localidade
- `date_from` - Data inicial (YYYY-MM-DD)
- `date_to` - Data final (YYYY-MM-DD)

**Exemplo:**
```bash
curl "http://localhost:3000/api/v1/analytics/nps?department=Engineering"
```

---

## Dashboard Web

### Rotas

| Rota | Descrição |
|------|-----------|
| `/` | Dashboard principal |
| `/dashboards/company` | Visão da empresa |
| `/dashboards/departments` | Visão por departamentos |
| `/dashboards/trends` | Tendências |
| `/dashboards/:id/employee` | Perfil do funcionário |

---

## Estrutura do Projeto

```
tech_playground/
├── app/
│   ├── controllers/
│   │   └── api/v1/           # Controllers da API
│   │       └── analytics/    # Endpoints de analytics
│   ├── models/
│   │   ├── employee.rb       # Modelo de funcionário
│   │   └── response.rb       # Modelo de resposta
│   ├── services/
│   │   ├── analytics/        # Services de analytics
│   │   │   ├── dashboard_service.rb
│   │   │   ├── favorability_service.rb
│   │   │   └── nps_service.rb
│   │   └── csv_importer.rb   # Importador de CSV
│   └── views/
│       └── dashboards/       # Views do dashboard
├── config/
│   ├── routes.rb             # Rotas da aplicação
│   └── database.yml          # Configuração do banco
├── db/
│   └── migrate/              # Migrations
├── lib/tasks/
│   └── import_csv.rake       # Task de importação
├── spec/                     # Testes RSpec
├── docker-compose.yml        # Configuração Docker
├── Dockerfile.dev            # Dockerfile para desenvolvimento
└── entrypoint.sh             # Script de inicialização
```

---

## Conceitos do Dataset

### Escala Likert (1-5)

- **1**: Discordo Totalmente
- **2**: Discordo
- **3**: Neutro
- **4**: Concordo (Favorável)
- **5**: Concordo Totalmente (Favorável)

### Favorabilidade

Porcentagem de respostas favoráveis (4 ou 5):

```
Favorabilidade = (Respostas >= 4) / Total × 100
```

### eNPS (Employee Net Promoter Score)

Baseado na pergunta: "De 0 a 10, qual a probabilidade de recomendar a empresa?"

- **Promoters**: 9-10
- **Passives**: 7-8
- **Detractors**: 0-6

```
eNPS = % Promoters - % Detractors
```

**Interpretação:**
- Excelente: > 70
- Muito Bom: 50-70
- Bom: 30-50
- Precisa Melhorar: 0-30
- Crítico: < 0

---

## Tarefas Implementadas

- [x] **Task 1**: Banco de Dados PostgreSQL
- [x] **Task 2**: Dashboard com Tailwind CSS
- [x] **Task 3**: Suite de Testes (RSpec)
- [x] **Task 4**: Docker Compose Setup
- [x] **Task 6**: Visualização - Nível Empresa
- [x] **Task 7**: Visualização - Nível Departamento
- [x] **Task 9**: API RESTful

---

## Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `RAILS_ENV` | Ambiente Rails | development |
| `DATABASE_URL` | URL do banco de dados | postgres://postgres:postgres@db:5432/app_development |
| `PORT` | Porta do servidor | 3000 |
| `BUNDLE_PATH` | Caminho das gems | /usr/local/bundle |

---

## Troubleshooting

### Banco de dados não conecta

```bash
# Verifique se o container do banco está rodando
docker-compose ps

# Recrie os containers
docker-compose down && docker-compose up --build
```

### Erro ao importar CSV

```bash
# Verifique se o arquivo data.csv existe na raiz do projeto
ls -la data.csv

# Execute a importação
docker-compose exec web bundle exec rake data:import
```

### Limpar tudo e recomeçar

```bash
docker-compose down -v
docker-compose up --build
docker-compose exec web bundle exec rake data:import
```

---

## Licença

Este projeto foi desenvolvido como parte do Tech Playground Challenge.
