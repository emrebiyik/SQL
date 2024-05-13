
CREATE DATABASE Manufacturer;

USE Manufacturer;

-- Create the Suppliers table
CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL ,
    activation_status BIT NOT NULL
)

-- Create the Components table
CREATE TABLE Components(
    -- component_id INT PRIMARY KEY,
    component_id INT PRIMARY KEY,
    component_name VARCHAR(100) NOT NULL,
    quantity int NOT NULL,
    supplied_date date NOT NULL,
    quantity_on_hand INT NOT NULL,
    description TEXT,
);

-- Create the Products table
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    quantity_on_hand INT NOT NULL
);

-- Component-Supplier relationship table
CREATE TABLE ComponentSupplier (
    component_id INT,
    supplier_id INT,
    FOREIGN KEY (component_id) REFERENCES Components(component_id),
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);

-- Component-Product relationship table
CREATE TABLE ProductComponent (
    component_id INT,
    product_id INT,
    FOREIGN KEY (component_id) REFERENCES Components(component_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);







