# Conversor de Diagramas de Caso de Uso

Este projeto implementa um conversor de uma linguagem personalizada para PlantUML, especificamente focado em diagramas de caso de uso. A ferramenta permite a criação de diagramas UML de maneira simplificada, usando uma sintaxe mais concisa.

## Instalação

### Pré-requisitos
- GHC (Glasgow Haskell Compiler)
- Cabal ou Stack

### Passos para instalação

1. Clone o repositório:
```bash
git clone [url-do-repositório]
cd quartoProjeto
```

2. Compile o projeto:
```bash
ghc -o converter Main.hs
```

## Uso

Execute o conversor passando o arquivo de entrada e o arquivo de saída:

```bash
./converter input.txt output.txt
```

O arquivo de saída conterá o código PlantUML correspondente, que pode ser usado com qualquer ferramenta compatível com PlantUML para gerar o diagrama visual.

## Sintaxe da Linguagem

### Definindo Módulos (Pacotes)

Um módulo (ou pacote) agrupa casos de uso relacionados:

```
module("Nome do Módulo") {
    case 'Nome do Caso de Uso',
    case 'Outro Caso de Uso' as ALIAS,
    actor 'Ator Interno'
}
```

### Definindo Atores

Atores podem ser definidos dentro ou fora de módulos:

```
actor 'Nome do Ator';
```

### Definindo Casos de Uso

Casos de uso são definidos dentro de módulos:

```
case 'Nome do Caso de Uso',
case 'Outro Caso de Uso' as ALIAS
```

O parâmetro `as ALIAS` é opcional e permite referenciar o caso de uso por um alias mais curto nas relações.

### Definindo Relacionamentos

Os relacionamentos conectam atores e casos de uso:

```
'Ator' -- 'Caso de Uso'       // Associação
'Caso A' -e> 'Caso B'         // Extensão
'Caso A' -i> 'Caso B'         // Inclusão
'Caso A' ->> 'Caso B'         // Generalização
```

É possível usar o nome completo ou o alias nas relações:

```
'Ator' -- ALIAS
ALIAS1 -e> ALIAS2
```

## Exemplo Completo

```
module("Hospital Reception"){
    case 'Schedule Patient Appointment',
    case 'Schedule Patient Hospital Admission' as SPHA,
    case 'Patient Registration' as PR,
    actor 'Receptionist'
}

actor 'Doctor';

'Receptionist' -- 'Schedule Patient Appointment'
'Receptionist' -- SPHA
Doctor -- PR
PR -e> SPHA
```

Este exemplo define um módulo "Hospital Reception" com três casos de uso e um ator interno, além de um ator externo "Doctor". As relações mostram as interações entre os atores e casos de uso.

## Tipos de Relacionamentos

| Sintaxe | Tipo | Descrição |
|---------|------|-----------|
| `--` | Associação | Conexão básica entre ator e caso de uso |
| `-e>` | Extensão | Um caso de uso estende outro |
| `-i>` | Inclusão | Um caso de uso inclui outro |
| `->>` | Generalização | Relação de herança/generalização |

## Considerações e Limitações

- Os nomes podem ser delimitados por aspas simples (`'`) ou duplas (`"`).
- Em relacionamentos, pode-se usar tanto o nome completo quanto o alias.
- Todos os identificadores referenciados em relacionamentos devem estar definidos no diagrama.
- A sintaxe é sensível a espaços em excesso, mas o conversor tenta normalizar os identificadores.

## Licença

[Incluir informações de licença]
