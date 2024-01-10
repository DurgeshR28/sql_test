CREATE TABLE suppliers (
    supplier_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    supplier_name VARCHAR2(100) NOT NULL,
    supplier_contact_name VARCHAR2(100) NOT NULL,
    supplier_house_number VARCHAR2(10),
    supplier_street_name_1 VARCHAR2(50),
    supplier_street_name_2 VARCHAR2(50),
    supplier_city VARCHAR2(50),
    supplier_country VARCHAR2(50),
    supplier_contact_number VARCHAR2(20) NOT NULL,
    supplier_contact_number2 VARCHAR2(20),
    supplier_email VARCHAR2(100) NOT NULL
);

CREATE TABLE orders (
    order_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_ref VARCHAR2(50) NOT NULL,
    order_date DATE NOT NULL,
    supplier_id NUMBER NOT NULL,
    order_total_amount NUMBER(10,2) NULL,
    order_line_amount NUMBER(10,2) NULL,
    order_description VARCHAR2(255),
    order_status VARCHAR2(50),
    CONSTRAINT fk_orders_suppliers FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

CREATE TABLE invoices (
    invoice_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id NUMBER NOT NULL,
    invoice_reference VARCHAR2(50) NOT NULL,
    invoice_date DATE NOT NULL,
    invoice_status VARCHAR2(50),
    invoice_hold_reason VARCHAR2(255),
    invoice_amount NUMBER(10,2) NOT NULL,
    invoice_description VARCHAR2(255),
    CONSTRAINT fk_invoices_orders FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

