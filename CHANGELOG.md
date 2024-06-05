# Changelog

## 2024-06-04

- [X] Validação que verifica a quantidade máxima de requests abertas;
- [X] validação na doação para não doar 0;
- [X] mais algum campo na struct, ex.: total de doações;
- [X] validação no getOpenRequests (quantidade máxima);
- [X] Validação que verifica a quantidade máxima de requests abertas por autor;
- [X] Validação para não criar requests com metas zeradas;
- [X] validações na criação de request (campos e duplicidade de author se request aberta);
- [X] não deixar doar para requests fechadas;
- [X] não permitir doar para request muito antiga (fecha automaticamente por tempo);
- [X] admin do contrato pode fechar requests suspeitas;
- [X] request ter um status, aí quando cadastrada, fica pendente e admin tem de aprovar;
- [X] admin aprovar a última requisição feita;
- [X] requests não aprovadas são desconsideradas das abertas
- [X] admin pode "desaprovar" uma requisição feita: efeito de suspensão;
- [X] blacklists de carteiras - admin pode cadastrar carteiras bloqueadas;
- [X] blacklists de carteiras - admin pode remover carteiras bloqueadas;
- [X] Admin pode dar privilégio de admin;
- [X] Admin pode remover privilégio de admin;
