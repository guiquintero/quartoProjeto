--Felipe Merenda Izidorio a64379
--Guilherme Quintero Lorenzi a64378
-- para compilar a main: "ghc -o converter Main.hs"
-- para testar: "./converter input.txt output.txt"

--input.txt

--module("Hospital Reception"){
--    case 'Schedule Patient Appointment',
--    case 'Schedule Patient Hospital Admission' as SPHA,
--    case 'Patient Registration' as PR,
--    case 'Patient Hospital Admission' as PHA,
--    case 'File Insurance Forms / Claims' as FIFC,
--    case 'File Medical Reports' as FMR,
--    case 'Outpatient Hospital Admission' as OHA,
--    case 'Inpatient Hospital Admission' as IHA,
--    case 'Bed Allotment'
--}

--actor 'Receptionist';


--'Receptionist' -- 'Schedule Patient Appointment'
--'Receptionist' -- SPHA
--'Receptionist' -- PR
--'Receptionist' -- PHA
--'Receptionist' -- FIFC
--'Receptionist' -- FMR
--'Receptionist' -e> FMR
--PR -e> SPHA
--PR -e> 'Schedule Patient Appointment'
--PHA -i> PR
--IHA -i> 'Bed Allotment'
--OHA ->> PHA
--IHA ->> PHA


module Main where

import Data.Char (isAlphaNum, isSpace)
import Data.List (intercalate)
import System.Environment (getArgs)
import System.IO (readFile, writeFile)
import Text.ParserCombinators.Parsec
import Control.Monad (void)
import Debug.Trace (trace)
import Data.Maybe (catMaybes)

-- Tipos de dados para armazenar a estrutura do diagrama
data Diagram = Diagram {
    modules :: [Module],
    actors :: [Actor],
    relationships :: [Relationship]
} deriving (Show)

data Module = Module {
    moduleName :: String,
    useCases :: [UseCase],
    moduleActors :: [Actor] 
} deriving (Show)

data UseCase = UseCase {
    useCaseName :: String,
    alias :: Maybe String
} deriving (Show)

data Actor = Actor {
    actorName :: String
} deriving (Show)

data Relationship = Relationship {
    source :: String,
    target :: String,
    relationshipType :: RelationType
} deriving (Show)

data RelationType = Association | Extend | Include | Generalization | Other String
    deriving (Show)

-- Parser para a linguagem personalizada
parseInput :: Parser Diagram
parseInput = do
    optional spaces
    result <- do
        mods <- many (try moduleParser)
        acts <- many (try actorParser)
        rels <- many (try relationshipParser)
        return $ Diagram mods acts rels
    optional spaces
    eof
    return result

-- Parser para módulos
moduleParser :: Parser Module
moduleParser = do
    try (string "module") <|> try (string "module ")
    optional spaces
    char '('
    optional spaces
    name <- quotedString
    optional spaces
    char ')'
    optional spaces
    char '{'
    optional spaces
    elements <- sepEndBy moduleElementParser spaces
    optional spaces
    char '}'
    optional spaces
    
    let useCases' = [uc | Left uc <- elements]
        actors' = [a | Right a <- elements]
    
    return $ Module name useCases' actors'

-- Parser para elementos dentro de um módulo (caso de uso ou ator)
moduleElementParser :: Parser (Either UseCase Actor)
moduleElementParser = (try (Left <$> useCaseParser)) <|> (Right <$> actorParser)

-- Parser para casos de uso
useCaseParser :: Parser UseCase
useCaseParser = do
    try (string "case") <|> try (string "case ")
    optional spaces
    name <- quotedString
    alias <- optionMaybe (try (optional spaces >> string "as" >> optional spaces >> many1 (satisfy (\c -> isAlphaNum c || c == '_'))))
    optional (oneOf ",;")
    return $ UseCase name alias

-- Parser para atores
actorParser :: Parser Actor
actorParser = do
    try (string "actor") <|> try (string "actor ")
    optional spaces
    name <- quotedString
    optional spaces
    optional (char ';')
    optional spaces
    return $ Actor name

-- Função auxiliar para remover espaços em branco no início e no fim de uma string
trim :: String -> String
trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

-- Parser para identificadores ou strings com aspas
quotedOrIdentifier :: Parser String
quotedOrIdentifier = do
    result <- try quotedString <|> many1 (satisfy (\c -> isAlphaNum c || c == '_'))
    return $ trim result  -- Aplicar trim para remover espaços extras

-- Parser para relacionamentos
relationshipParser :: Parser Relationship
relationshipParser = do
    source <- quotedOrIdentifier
    optional spaces
    relType <- relationTypeParser
    optional spaces
    target <- quotedOrIdentifier
    optional spaces
    return $ Relationship (trim source) (trim target) relType  -- Garantir que não há espaços extras

-- Parser para tipos de relacionamento
relationTypeParser :: Parser RelationType
relationTypeParser = choice [
    try (string "--") >> return Association,
    try (string "-e>") >> return Extend,
    try (string "-i>") >> return Include,
    try (string "->>") >> return Generalization,
    try (string "->") >> return (Other "->"),
    try (string "-->") >> return (Other "-->")
    ]

-- Parser para strings com aspas (suporta tanto aspas simples quanto duplas)
quotedString :: Parser String
quotedString = quotedWithSingleQuotes <|> quotedWithDoubleQuotes <|> plainIdentifier
  where
    quotedWithSingleQuotes = between (char '\'') (char '\'') (many (noneOf "'"))
    quotedWithDoubleQuotes = between (char '"') (char '"') (many (noneOf "\""))
    plainIdentifier = many1 (satisfy (\c -> isAlphaNum c || c == ' '))

-- Conversão para PlantUML
generatePlantUML :: Diagram -> String
generatePlantUML diagram = 
    "@startuml\n" ++
    "left to right direction\n\n" ++
    actorsToPlantUML (actors diagram) ++
    "\n" ++
    modulesToPlantUML (modules diagram) ++
    "\n" ++
    relationshipsToPlantUML (relationships diagram) ++
    "\n@enduml"

-- Conversão de atores para PlantUML
actorsToPlantUML :: [Actor] -> String
actorsToPlantUML actors = intercalate "\n" (map actorToPlantUML actors)

actorToPlantUML :: Actor -> String
actorToPlantUML actor = "actor \"" ++ actorName actor ++ "\""

-- Conversão de módulos para PlantUML
modulesToPlantUML :: [Module] -> String
modulesToPlantUML modules = intercalate "\n\n" (map moduleToPlantUML modules)

moduleToPlantUML :: Module -> String
moduleToPlantUML module' = 
    "package \"" ++ moduleName module' ++ "\" {\n" ++
    concatMap (\uc -> "    " ++ useCaseToPlantUML uc ++ "\n") (useCases module') ++
    concatMap (\a -> "    " ++ actorToPlantUML a ++ "\n") (moduleActors module') ++
    "}"

useCaseToPlantUML :: UseCase -> String
useCaseToPlantUML useCase = 
    "usecase \"" ++ useCaseName useCase ++ "\"" ++ 
    case alias useCase of
        Just a -> " as " ++ a
        Nothing -> ""

-- Conversão de relacionamentos para PlantUML
relationshipsToPlantUML :: [Relationship] -> String
relationshipsToPlantUML relationships = intercalate "\n" (map relationshipToPlantUML relationships)

relationshipToPlantUML :: Relationship -> String
relationshipToPlantUML rel = 
    getNodeName (source rel) ++ " " ++ 
    getRelationSymbol (relationshipType rel) ++ " " ++
    getNodeName (target rel) ++
    getRelationLabel (relationshipType rel)

getNodeName :: String -> String
getNodeName name = if any isSpace name then "\"" ++ name ++ "\"" else name

getRelationSymbol :: RelationType -> String
getRelationSymbol Association = "--"
getRelationSymbol Extend = "..>"
getRelationSymbol Include = "..>"
getRelationSymbol Generalization = "..|>"
getRelationSymbol (Other s) = s

getRelationLabel :: RelationType -> String
getRelationLabel Extend = " : <<extend>>"
getRelationLabel Include = " : <<include>>"
getRelationLabel _ = ""

-- Função para validar o diagrama
validateDiagram :: Diagram -> Either String Diagram
validateDiagram diagram = do
    let allActors = actors diagram ++ concatMap moduleActors (modules diagram)
        actorNames = map (trim . actorName) allActors
        allUseCases = concatMap useCases (modules diagram)
        
        -- Extrair todos os identificadores de casos de uso (nomes e aliases)
        useCaseNames = map (trim . useCaseName) allUseCases
        useCaseAliases = map trim $ catMaybes $ map alias allUseCases
        
        -- Todas as entidades válidas no diagrama
        allEntities = actorNames ++ useCaseNames ++ useCaseAliases
        
        -- Função para verificar se um identificador existe no diagrama
        checkEntity :: String -> Either String ()
        checkEntity id = 
            let trimmedId = trim id
            in
            if trimmedId `elem` allEntities
                then Right ()
                else Left $ "Erro: Entidade '" ++ trimmedId ++ "' referenciada mas não declarada."
    
    -- Verificar todos os relacionamentos
    mapM_ (\rel -> do
        checkEntity (source rel)
        checkEntity (target rel)) (relationships diagram)
    
    Right diagram  -- Se chegarmos aqui, todas as validações passaram

-- Função auxiliar para converter Maybe em lista
maybeToList :: Maybe a -> [a]
maybeToList Nothing = []
maybeToList (Just x) = [x]

-- Função principal
main :: IO ()
main = do
    args <- getArgs
    case args of
        [inputFile, outputFile] -> do
            input <- readFile inputFile
            putStrLn $ "Lendo arquivo: " ++ inputFile
            putStrLn $ "Conteúdo: \n" ++ input
            case parse parseInput inputFile input of
                Left err -> putStrLn $ "Erro de parsing: " ++ show err
                Right diagram -> 
                    case validateDiagram diagram of
                        Left err -> putStrLn err
                        Right validDiagram -> do
                            let plantUML = generatePlantUML validDiagram
                            writeFile outputFile plantUML
                            putStrLn $ "Arquivo convertido com sucesso: " ++ outputFile
                            putStrLn $ "Conteúdo gerado: \n" ++ plantUML
        _ -> putStrLn "Uso: ./converter input.txt output.txt"

-- Função para testar a conversão
testConversion :: String -> IO ()
testConversion input = 
    case parse parseInput "" input of
        Left err -> putStrLn $ "Erro de parsing: " ++ show err
        Right diagram -> 
            case validateDiagram diagram of
                Left err -> putStrLn err
                Right validDiagram -> putStrLn $ generatePlantUML validDiagram
