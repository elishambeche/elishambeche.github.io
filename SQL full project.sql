CREATE DATABASE farmers_choice_sales_demo;

USE farmers_choice_sales_demo;


CREATE TABLE customers (
    CustomerID INT,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Gender VARCHAR(10),
    County VARCHAR(50),
    PhoneNumber VARCHAR(15),
    Email VARCHAR(100)
);

CREATE TABLE products (
    ProductID INT,
    ProductName VARCHAR(100),
    Category VARCHAR(50),
    UnitPrice DECIMAL(10,2)
);

CREATE TABLE sales (
    SaleID INT,
    CustomerID INT,
    ProductID INT,
    SaleDate DATE,
    Quantity INT,
    TotalAmount DECIMAL(10,2)
);

-- Data cleaning Removing duplicates

-- Adding a temporary primary key for safe deletion

ALTER TABLE customers ADD COLUMN temp_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY;

-- Removing duplicates safely using temp_id 
WITH ranked_customers AS (
    SELECT temp_id,
           ROW_NUMBER() OVER (
               PARTITION BY CustomerID, PhoneNumber, Email
               ORDER BY CustomerID
           ) AS rn
    FROM customers
)
DELETE FROM customers
WHERE temp_id IN (
    SELECT temp_id
    FROM ranked_customers
    WHERE rn > 1
);

ALTER TABLE customers DROP COLUMN tem_id;



-- Removing null values


-- Temporarily disable safe updates so we can delete
SET SQL_SAFE_UPDATES = 0;



-- Delete rows with null or empty FirstName, PhoneNumber, or Email
DELETE FROM customers
WHERE (
    FirstName IS NULL OR TRIM(FirstName) = ''
    OR PhoneNumber IS NULL OR TRIM(PhoneNumber) = ''
    OR Email IS NULL OR TRIM(Email) = ''
);

-- Re-enable safe updates
SET SQL_SAFE_UPDATES = 1;


-- A FEW QUERIES

-- 1. View all customers from Nairobi
SELECT * FROM customers
WHERE County = 'Nairobi';


-- 2. Find all pig products costing more than 1,000 KES
SELECT * FROM products
WHERE UnitPrice > 1000;

-- 3. Get sales made in July 2025
SELECT * FROM sales
WHERE SaleDate BETWEEN '2025-07-01' AND '2025-07-31';

-- 4. Count total customers
SELECT COUNT(*) AS TotalCustomers
FROM customers;

SELECT*
FROM sales;


-- 5. Total sales value
SELECT SUM(Quantity * UnitPrice) AS TotalSalesValue
FROM sales
JOIN products ON sales.ProductID = products.ProductID;

-- 6. Average price of pigs sold
SELECT AVG(UnitPrice) AS AvgPrice
FROM products;


-- 7. Show all sales with customer names and product names
SELECT s.SaleID, CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
       p.ProductName, s.Quantity, p.UnitPrice, (s.Quantity * p.UnitPrice) AS TotalAmount, s.SaleDate
FROM sales s
JOIN customers c ON s.CustomerID = c.CustomerID
JOIN products p ON s.ProductID = p.ProductID;

-- 8. Total sales per customer
SELECT CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName,
       SUM(s.Quantity * p.UnitPrice) AS TotalSpent
FROM sales s
JOIN customers c ON s.CustomerID = c.CustomerID
JOIN products p ON s.ProductID = p.ProductID
GROUP BY c.CustomerID, c.FirstName, c.LastName
ORDER BY TotalSpent DESC;


-- 9. Top 5 best-selling pig products
SELECT p.ProductName, SUM(s.Quantity) AS TotalSold
FROM sales s
JOIN products p ON s.ProductID = p.ProductID
GROUP BY p.ProductID, p.ProductName
ORDER BY TotalSold DESC
LIMIT 5;


-- 10. Customers who have never bought anything
SELECT c.CustomerID, CONCAT(c.FirstName, ' ', c.LastName) AS CustomerName
FROM customers c
LEFT JOIN sales s ON c.CustomerID = s.CustomerID
WHERE s.SaleID IS NULL;

-- 11. Total revenue per month

SELECT DATE_FORMAT(s.SaleDate, '%Y-%m') AS Month,
       SUM(s.Quantity * p.UnitPrice) AS TotalRevenue
FROM sales s
JOIN products p ON s.ProductID = p.ProductID
GROUP BY Month
ORDER BY Month;

-- Customers who spent more than 100,000

SELECT CustomerID, FirstName, LastName
FROM customers
WHERE CustomerID IN (
    SELECT CustomerID
    FROM sales
    GROUP BY CustomerID
    HAVING SUM(TotalAmount) > 100000
);

-- Product names of most expensive sale

SELECT ProductName
FROM products
WHERE ProductID IN (
    SELECT ProductID
    FROM sales
    WHERE TotalAmount = (
        SELECT MAX(TotalAmount) FROM sales
    )
);

-- sales above average sale amount

SELECT SaleID, CustomerID, TotalAmount
FROM sales
WHERE TotalAmount > (
    SELECT AVG(TotalAmount) FROM sales
);

-- top 5 selling products CTE

WITH product_sales AS (
    SELECT ProductID, SUM(Quantity) AS TotalSold
    FROM sales
    GROUP BY ProductID
)
SELECT p.ProductName, ps.TotalSold
FROM product_sales ps
JOIN products p ON ps.ProductID = p.ProductID
ORDER BY ps.TotalSold DESC
LIMIT 5;

-- Sales above average CTE

WITH avg_sales AS (
    SELECT AVG(TotalAmount) AS AvgAmount
    FROM sales
)
SELECT s.SaleID, s.TotalAmount
FROM sales s
JOIN avg_sales a ON s.TotalAmount > a.AvgAmount;










 

 
 