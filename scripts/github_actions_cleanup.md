# Guia de Limpeza de Recursos no GitHub Actions

Este guia explica como usar o workflow `terraform-cleanup.yml` para resolver problemas comuns durante a destruição de recursos do Confluent Cloud via GitHub Actions.

## Problema: Falha ao Excluir Cluster Kafka

O erro:
```
Error: error deleting Kafka Cluster "lkc-rx8vy0": 403 Forbidden: There was a problem: failed preconditions: 
Failed to deactivate cluster lkc-rx8vy0, because it still runs with active cluster(s): lcc-5oj6kn,lcc-13p58z,lcc-dxnw7y
```

Este erro ocorre porque o Terraform está tentando excluir um cluster Kafka que ainda possui conectores ativos. Os conectores devem ser excluídos primeiro.

## Solução: Workflow de Limpeza

Foi adicionado um novo workflow chamado `terraform-cleanup.yml` que pode ser executado manualmente no GitHub Actions.

### Como usar:

1. Acesse a aba "Actions" no seu repositório GitHub
2. Selecione o workflow "Terraform Cleanup" na lista
3. Clique em "Run workflow"
4. Configure as opções:
   - **Destroy connectors first**: Defina como `true` para excluir conectores antes do cluster
   - **Remove problematic resources from state**: Defina como `true` se precisar remover recursos problemáticos do estado
   - **Resource pattern**: Padrão para filtrar recursos (ex: `connector`, `privatelink`)
5. Clique em "Run workflow"

### O que o workflow faz:

1. **Lista recursos no estado**: Mostra todos os recursos no estado do Terraform
2. **Remove recursos problemáticos**: Remove recursos que correspondem ao padrão especificado
3. **Destrói conectores primeiro**: Tenta destruir conectores via Terraform
4. **Tenta destruição completa**: Executa `terraform destroy`
5. **Verifica erros de dependência**: Se falhar devido a conectores ativos
6. **Destrói conectores via API**: Usa a API do Confluent Cloud para excluir conectores
7. **Executa destruição final**: Tenta `terraform destroy` novamente

## Problemas comuns e soluções

### 1. Erro "Invalid target address"

**Problema**: O Terraform não consegue encontrar o recurso que você está tentando remover do estado.

**Solução**: Use o workflow com a opção "Remove problematic resources from state" definida como `true` e especifique um padrão que corresponda aos recursos problemáticos.

### 2. Erro "Failed to deactivate cluster because it still runs with active cluster(s)"

**Problema**: O cluster Kafka tem conectores ativos que impedem sua exclusão.

**Solução**: Use o workflow com a opção "Destroy connectors first" definida como `true`.

### 3. Recursos de Private Link presos no estado

**Problema**: Recursos de Private Link não podem ser excluídos corretamente.

**Solução**: Use o workflow com "Remove problematic resources from state" como `true` e "Resource pattern" como `privatelink`.

## Exemplo de uso

Para resolver o erro específico de conectores ativos:

1. Execute o workflow com:
   - "Destroy connectors first": `true`
   - "Remove problematic resources from state": `false`
   - "Resource pattern": deixe em branco

2. Se ainda houver problemas, execute novamente com:
   - "Destroy connectors first": `true`
   - "Remove problematic resources from state": `true`
   - "Resource pattern": `connector`

3. Execute uma última vez com todas as opções padrão para finalizar a destruição.

## Notas importantes

- Este workflow requer que os secrets do GitHub estejam configurados corretamente
- A exclusão de recursos via API pode levar algum tempo para propagar
- Sempre verifique o console do Confluent Cloud para confirmar que os recursos foram excluídos