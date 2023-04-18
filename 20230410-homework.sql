use Northwind;
-- 找出和最貴的產品同類別的所有產品 
SELECT c.CategoryName, p.ProductID, p.ProductName
FROM Products p
INNER JOIN Categories c ON c.CategoryID = (
SELECT p.CategoryID
FROM Products p
WHERE p.UnitPrice =
(
SELECT MAX(UnitPrice)
FROM Products p
));

-- 找出和最貴的產品同類別最便宜的產品
SELECT c.CategoryName, p.ProductID, p.ProductName, p.UnitPrice
FROM Products p
INNER JOIN Categories c ON c.CategoryID = (
SELECT p.CategoryID
FROM Products p
WHERE p.UnitPrice =
(
SELECT MAX(UnitPrice)
FROM Products p))
WHERE p.UnitPrice = (SELECT MIN(UnitPrice) FROM Products WHERE CategoryID = c.CategoryID);
-- 計算出上面類別最貴和最便宜的兩個產品的價差
SELECT (MAX(p.UnitPrice) - MIN(p.UnitPrice)) AS gap 
FROM Products p, Categories c
WHERE c.CategoryID =(
SELECT p.CategoryID
FROM Products p
WHERE p.UnitPrice =
(
SELECT MAX(UnitPrice)
FROM Products p
));
-- 找出沒有訂過任何商品的客戶所在的城市的所有客戶
SELECT *
FROM Customers c
WHERE NOT EXISTS(
	SELECT * FROM Orders
	WHERE CustomerID = c.CustomerID
)
-- 找出第 5 貴跟第 8 便宜的產品的產品類別
WITH t1 AS (
	SELECT
		ProductID, ProductName, UnitPrice,CategoryID,
		ROW_NUMBER() OVER (
			ORDER BY UnitPrice DESC
		) AS NoDesc,
		ROW_NUMBER() OVER (
			ORDER BY UnitPrice 
		) AS NoAsc
	FROM Products
)
SELECT c.CategoryName FROM t1
INNER JOIN Categories c ON t1.CategoryID = c.CategoryID
WHERE NoDesc = 5 OR NoAsc = 8

-- 找出誰買過第 5 貴跟第 8 便宜的產品
WITH t1 AS (
	SELECT
		ProductID, ProductName, UnitPrice,CategoryID,
		ROW_NUMBER() OVER (
			ORDER BY UnitPrice DESC
		) AS NoDesc,
		ROW_NUMBER() OVER (
			ORDER BY UnitPrice 
		) AS NoAsc
	FROM Products
)
SELECT c.CustomerID, od.ProductID
FROM Customers c
INNER JOIN Orders o ON o.CustomerID = c.CustomerID
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
WHERE od.ProductID IN (
	SELECT ProductID FROM t1
	WHERE NoDesc = 5 OR NoAsc = 8
)

-- 找出誰賣過第 5 貴跟第 8 便宜的產品
WITH t1 AS (
	SELECT
		ProductID, ProductName, UnitPrice,CategoryID,
		ROW_NUMBER() OVER (
			ORDER BY UnitPrice DESC
		) AS NoDesc,
		ROW_NUMBER() OVER (
			ORDER BY UnitPrice 
		) AS NoAsc
	FROM Products
)
SELECT e.EmployeeID, ProductID
FROM Employees e
INNER JOIN Orders o ON o.EmployeeID = e.EmployeeID
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
WHERE od.ProductID IN (
SELECT ProductID
FROM t1
WHERE NoDesc = 5 Or NoAsc = 8
)
-- 找出 13 號星期五的訂單 (惡魔的訂單)
SELECT OrderID, CONVERT(varchar, OrderDate,111) as orderdate
FROM Orders
WHERE DATEPART(day,OrderDate) = 13 AND DATEPART(weekday,OrderDate) = 6;
-- 找出誰訂了惡魔的訂單
SELECT OrderID, CustomerID, CONVERT(varchar, OrderDate,111) as orderdate
FROM Orders
WHERE DATEPART(day,OrderDate) = 13 AND DATEPART(weekday,OrderDate) = 6;
-- 找出惡魔的訂單裡有什麼產品
SELECT  DISTINCT od.ProductID, p.ProductName
FROM Orders o
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
INNER JOIN Products p ON p.ProductID = od.ProductID
WHERE DATEPART(day,OrderDate) = 13 AND DATEPART(weekday,OrderDate) = 6
ORDER BY od.ProductID;

-- 列出從來沒有打折 (Discount) 出售的產品
SELECT *
FROM Products
WHERE Discontinued = 0;

-- 列出購買非本國的產品的客戶
SELECT DISTINCT c.CustomerID, c.ContactName, c.City
FROM Customers c
INNER JOIN Orders o ON o.CustomerID = c.CustomerID
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
WHERE od.ProductID IN (
	SELECT  p.ProductID
	FROM Products p 
	INNER JOIN Suppliers s ON s.SupplierID = p.SupplierID
	WHERE s.City <> c.City
)

-- 列出在同個城市中有公司員工可以服務的客戶
SELECT c.CustomerID
FROM Employees e
INNER JOIN Customers c ON c.City = e.City
-- 列出那些產品沒有人買過
SELECT p.ProductID
FROM Products p
WHERE NOT EXISTS(
SELECT od.ProductID
FROM [Order Details] od
)

----------------------------------------------------------

-- 列出所有在每個月月底的訂單
SELECT o.OrderDate, o.OrderID
FROM Orders o
WHERE DATEPART(day,o.OrderDate) >= 20 
-- 列出每個月月底售出的產品
SELECT o.OrderDate, o.OrderID, p.ProductID
FROM Orders o
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
INNER JOIN Products p ON p.ProductID = od.ProductID
WHERE DATEPART(day,o.OrderDate) >= 20 
-- 找出有敗過最貴的三個產品中的任何一個的前三個大客戶
 
-- 找出有敗過銷售金額前三高個產品的前三個大客戶

-- 找出有敗過銷售金額前三高個產品所屬類別的前三個大客戶

-- 列出消費總金額高於所有客戶平均消費總金額的客戶的名字，以及客戶的消費總金額
WITH t1 AS(
SELECT SUM((od.UnitPrice*od.Quantity)*(1-od.Discount)) totalPrice, c.CustomerID CustomerID 
FROM Customers c
INNER JOIN Orders o ON o.CustomerID = c.CustomerID
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
GROUP BY c.CustomerID
)
SELECT CustomerID, totalPrice 
FROM t1
WHERE totalPrice > (
SELECT AVG(totalPrice) FROM t1)
-- 列出最熱銷的產品，以及被購買的總金額
SELECT TOP 1 SUM(od.UnitPrice) sum_price, od.ProductID
FROM [Order Details] od
GROUP BY od.ProductID
ORDER BY SUM(od.Quantity) DESC
-- 列出最少人買的產品
SELECT TOP 1 SUM(od.Quantity) sum_quantity, od.ProductID
FROM [Order Details] od
GROUP BY od.ProductID
ORDER BY SUM(od.Quantity) 
-- 列出最沒人要買的產品類別 (Categories)
SELECT TOP 1 SUM(od.Quantity) SumQuantity, c.CategoryID
FROM [Order Details] od
INNER JOIN Products p ON p.ProductID = od.ProductID
INNER JOIN Categories c ON c.CategoryID = p.CategoryID
GROUP BY c.CategoryID
ORDER BY SumQuantity
-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (含購買其它供應商的產品)



-- 列出跟銷售最好的供應商買最多金額的客戶與購買金額 (不含購買其它供應商的產品)
SELECT TOP 1 SUM((od.UnitPrice*od.Quantity)*(1-od.Discount)) totalPriec, c.CustomerID
FROM Customers c
INNER JOIN Orders o ON o.CustomerID = c.CustomerID
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
INNER JOIN Products p ON p.ProductID = od.ProductID
WHERE p.SupplierID = (
SELECT TOP 1 s.SupplierID
FROM Suppliers s
INNER JOIN Products p ON p.SupplierID = s.SupplierID
INNER JOIN [Order Details] od ON od.ProductID = p.ProductID
GROUP BY s.SupplierID
ORDER BY SUM(od.Quantity) DESC)
GROUP BY c.CustomerID
ORDER BY totalPriec DESC
-- 列出那些產品沒有人買過 ??
SELECT p.ProductID
FROM Products p
WHERE NOT EXISTS(
SELECT od.ProductID
FROM [Order Details] od
)
-- 列出沒有傳真 (Fax) 的客戶和它的消費總金額
WITH t1 AS(
SELECT SUM((od.UnitPrice*od.Quantity)*(1-od.Discount)) totalPrice, c.CustomerID CustomerID 
FROM Customers c
INNER JOIN Orders o ON o.CustomerID = c.CustomerID
INNER JOIN [Order Details] od ON od.OrderID = o.OrderID
GROUP BY c.CustomerID
)
SELECT CustomerID, totalPrice
FROM t1
WHERE CustomerID IN(
SELECT c.CustomerID
FROM Customers c
WHERE c.Fax IS NULL)
-- 列出每一個城市消費的產品種類數量

-- 列出目前沒有庫存的產品在過去總共被訂購的數量

-- 列出目前沒有庫存的產品在過去曾經被那些客戶訂購過

-- 列出每位員工的下屬的業績總金額

-- 列出每家貨運公司運送最多的那一種產品類別與總數量

-- 列出每一個客戶買最多的產品類別與金額

-- 列出每一個客戶買最多的那一個產品與購買數量

-- 按照城市分類，找出每一個城市最近一筆訂單的送貨時間
SELECT ShipCity, MAX(ShippedDate) recentDate
FROM ORDERS 
WHERE ShipCity IS NOT NULL
GROUP BY ShipCity;
-- 列出購買金額第五名與第十名的客戶，以及兩個客戶的金額差距
WITH t1 AS (
	SELECT
		ProductID, ProductName, UnitPrice,CategoryID,
		ROW_NUMBER() OVER (
			ORDER BY UnitPrice DESC
		) AS NoDesc,
		ROW_NUMBER() OVER (
			ORDER BY UnitPrice 
		) AS NoAsc
	FROM Products
);
