doubleMe x = x + x

doubleUs x y = (doubleMe x) + (doubleMe y)

doubleSmallNumber x = if x > 100 then x else doubleMe x


-- pattern matching

maximun' [x] = x
maximun' (x:xs) = max' x (maximun' xs)

max' x y = if (x > y) then x else y


replicate' 1 x = [x]
replicate' n x = (:) x (replicate (n - 1) x)


zipWith' _ [] _ = []
zipWith' _ _ [] = []
zipWith' f (x:xs) (y:ys) = f x y : zipWith' f xs ys


-- tipos concretos propios

data Point = Point Float Float deriving (Show)
data Shape = Circle Point Float | Rectangle Point Point deriving (Show)

surface :: Shape -> Float
surface (Circle _ r) = pi * r ^ 2
surface (Rectangle (Point x1 y1) (Point x2 y2)) = (abs $ x2 - x1) * (abs $ y2 - y1)

nudge :: Shape -> Float -> Float -> Shape
nudge (Circle (Point x y) r)  dx dy = Circle (Point (x + dx) (y + dy)) r
nudge (Rectangle (Point x1 y1) (Point x2 y2)) dx dy = Rectangle (Point (x1 + dx) (y1 + dy)) (Point (x2 + dx) (y2 + dy))

data Car = Car { model :: String, brand :: String, register :: String, year :: Int} deriving (Show)


-- constructores de tipos concretos propios

data Vector t = Vector t t t deriving (Show)  -- esto me permite crear el tipo concreto: Vector Int, Vector Float, ...

-- ":k Vector"  esto produce *->* que significa q recibe un tipo concreto y devuelve un tipo concreto

sumv (Vector x1 y1 z1) (Vector x2 y2 z2) = Vector (x1 + x2) (y1 + y2) (z1 + z2)


-- instanciar clases (definir comportamiento) para tipos concretos

data TrafficLight = Green | Yellow | Red

instance Eq TrafficLight where 
	Red == Red = True
	Yellow == Yellow = True
	Green == Green = True
	_ == _ = False

instance Show TrafficLight where
	show Red = "Red light"
	show Green = "Green light"
	show Yellow = "Yellow light"


class YesNo a where
	yesno :: a -> Bool

instance YesNo Int where
	yesno 0 = False
	yesno _ = True

instance YesNo [a] where
	yesno [] = False
	yesno _ = True
