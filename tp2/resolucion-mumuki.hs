--1
data Validated a = Valid a | Doubtful a String | Invalid String deriving (Eq, Show)
patrimonioAsquelCorp = Valid 2000000
empleadosNoditoInc = Doubtful 45 "contratron mas gente"
tickerJemaRoja = Invalid "no está mas en la bolsa"

--2
{--
valorMensual (Valid a) = Valid (div a 12)
valorMensual (Doubtful a b) = Doubtful (div a 12) b
valorMensual (Invalid a) = Invalid a
--}

--3
{--
mapValidated f (Valid a) = Valid (f a)
mapValidated f (Doubtful a b) = Doubtful (f a) b
mapValidated f (Invalid a) = Invalid a

longitudTicker a = mapValidated length a

valorMensual a = mapValidated (\x -> div x 12) a
--}

--4
{--
fmap (+ 4) (Just 4)
fmap (+ 4) [1,2,3]
fmap (+ 4) (Left 4)
--}

--5

instance Functor Validated where 
	fmap f (Valid a) = Valid (f a)
	fmap f (Doubtful a b) = Doubtful (f a) b
	fmap f (Invalid a) = Invalid a 

longitudTicker a = fmap length a

valorMensual a = fmap (\x -> div x 12) a

--6
{--
codigoUnico (Valid a1) (Valid a2) = Valid (a1 ++ ":" ++ a2)
codigoUnico (Valid a1) (Doubtful a2 b2) = Doubtful (a1 ++ ":" ++ a2) b2
codigoUnico (Valid a1) (Invalid a2) = Invalid a2
codigoUnico (Doubtful a1 b1) (Doubtful a2 b2) = Doubtful (a1 ++ ":" ++ a2) b1
codigoUnico (Doubtful a1 b1) (Invalid a2) = Invalid a2
codigoUnico (Doubtful a1 b1) (Valid a2) = Doubtful (a1 ++ ":" ++ a2) b1
codigoUnico (Invalid a1) (Invalid a2) = Invalid a1
--}

--7

aplicarBinarioValidated f (Valid a1) (Valid a2) = Valid (f a1 a2)
aplicarBinarioValidated f (Valid a1) (Doubtful a2 b2) = Doubtful (f a1 a2) b2
aplicarBinarioValidated _ (Valid a1) (Invalid a2) = Invalid a2
aplicarBinarioValidated f (Doubtful a1 b1) (Doubtful a2 b2) = Doubtful (f a1 a2) b1
aplicarBinarioValidated _ (Doubtful a1 b1) (Invalid a2) = Invalid a2
aplicarBinarioValidated f (Doubtful a1 b1) (Valid a2) = Doubtful (f a1 a2) b1
aplicarBinarioValidated _ (Invalid a1) (Invalid a2) = Invalid a1
{--
codigoUnico v1 v2 = aplicarBinarioValidated (\x y -> x ++ ":" ++ y) v1 v2
--}


--8

aplicarValidated (Valid f) (Valid a) = Valid (f a)
aplicarValidated (Doubtful f a) (Doubtful b c) = Doubtful (f b) a
aplicarValidated (Invalid a) _ = Invalid a
aplicarValidated _ (Invalid b) = Invalid b


--9

{--
aplicarValidated (Valid (+2)) (Valid 2)
aplicarValidated (Valid (*2)) (Valid 2)
--}

--10
import Control.Applicative

instance Applicative Validated where
	(<*>) = aplicarValidated
	pure = Valid

--12

codigoUnico a b = a ++ ":" ++ b


--13

validarIguales a b = if (a == b) then (Valid a) else Invalid ((show a) ++ " /= " ++ (show b))


--14

validarIgualesValidated (Valid a) (Valid b) = validarIguales a b
validarIgualesValidated (Doubtful a b) _ = Doubtful a b
validarIgualesValidated _ (Doubtful a b) = Doubtful a b
validarIgualesValidated (Invalid a) _ = Invalid a
validarIgualesValidated _ (Invalid a) = Invalid a


--15

bindValidated (Valid a) f = f a


--16

instance Monad Validated where
    return x = Valid x
    (Valid a) >>= f = f a
    (Invalid a) >>= f = Invalid a
    (Doubtful a b) >>= f = Doubtful a b
