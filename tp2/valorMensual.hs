data Validated = Valid Int | Doubtful Int String | Invalid String deriving (Eq, Show)
let patrimonioAsquelCorp = Valid 2000000
let empleadosNoditoInc = Doubtful 45 "contratron mas gente"
let tickerJemaRoja = Invalid "no está mas en la bolsa"

valorMensual :: (Int a) => a -> a
valorMensual Int = Int / 12
