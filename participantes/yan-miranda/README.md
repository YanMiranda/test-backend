# Teste Java - Sizebay

**Autor:** Yan Miranda

**Repositório Original:** https://github.com/YanMiranda/sizebay

## Tecnologias
- Java 17
- Spring Boot 3.3
- PostgreSQL (Stored Procedures)
- Nginx
- Docker

## Abordagem Arquitetural

Para atender aos requisitos de alta concorrência e restrição rígida de recursos (1.5 CPU / 550MB RAM), a solução focou em **reduzir a responsabilidade da aplicação** (Java) e **otimizar o I/O do Banco de Dados**.

### 1. Transacionalidade e Performance (Stored Procedures)
A lógica crítica de transação (débito/crédito) e validação de consistência foi migrada da camada de aplicação para o banco de dados via funções PL/pgSQL (`create_transaction`).
* **Por que:** Isso elimina o *overhead* de múltiplos *round-trips* (idas e vindas na rede) entre a API e o Banco dentro de uma mesma transação.
* **Resultado:** A operação torna-se atômica e o tempo de bloqueio (*lock*) dos registros ocorre estritamente dentro do motor do banco, liberando as conexões do pool Java muito mais rápido.

### 2. Otimização de Armazenamento e I/O
* **Tabelas UNLOGGED:** As tabelas do Postgres foram configuradas como `UNLOGGED` para reduzir a escrita no *Write Ahead Log* (WAL), priorizando a velocidade de inserção bruta exigida pelo teste de carga.
* **Tipagem Eficiente:** Uso de `CHAR(1)` para tipos fixos, otimizando o armazenamento e o tráfego de dados.

### 3. Resiliência e Alta Disponibilidade (Nginx Tuning)
O Nginx foi configurado não apenas como balanceador, mas como uma camada de proteção e resiliência:
* **Retry Policy:** Configuração de `proxy_next_upstream` para redirecionar requisições imediatamente para a instância vizinha em caso de falha ou timeout.
* **Keep-Alive:** Ajuste fino de conexões persistentes para evitar o custo de *handshake* TCP/SSL repetitivo.

### 4. Otimização de Recursos (JVM)
* **Fail Fast & Silent:** Exceções de negócio (`SaldoInsuficiente`, `ClienteNaoEncontrado`) foram configuradas sem a geração de *Stack Trace* (`fillInStackTrace`), economizando ciclos de CPU preciosos ao evitar o rastreamento da pilha em erros esperados.
* **DTOs:** Uso de Java Records para imutabilidade e menor consumo de memória no *Heap*.

## Como rodar
```bash
docker-compose up
```