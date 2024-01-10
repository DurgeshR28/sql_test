CREATE OR REPLACE PROCEDURE migrate_data
AS
BEGIN
    -- Begin a transaction for data integrity
    BEGIN
        -- Insert data into suppliers table
        INSERT INTO suppliers (supplier_name, supplier_contact_name, supplier_house_number,supplier_street_name_1,supplier_street_name_2,supplier_city,supplier_country,supplier_contact_number,supplier_contact_number2, supplier_email)

        SELECT 
            SUPPLIER_NAME, SUPP_CONTACT_NAME,
            supplier_house_number,
            supplier_street_name_1,
            supplier_street_name_2,
            supplier_city,
            supplier_country,
            REGEXP_REPLACE(phonenum1, '[^0-9]','') AS num,
            REGEXP_REPLACE(phonenum2, '[^0-9]','') AS num2
           ,SUPP_EMAIL
        FROM (
            SELECT SUPPLIER_NAME, SUPP_CONTACT_NAME, 
			REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 1) AS supplier_house_number,
            REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 2) AS supplier_street_name_1,
            REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 3) AS supplier_street_name_2,
            REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 4) AS supplier_city,
            REGEXP_SUBSTR(SUPP_ADDRESS, '[^,]+', 1, 5) AS supplier_country,
            REGEXP_SUBSTR(SUPP_CONTACT_NUMBER, '[^,]+', 1, 1) AS phonenum1,
            REGEXP_SUBSTR(SUPP_CONTACT_NUMBER, '[^,]+', 1, 2) AS phonenum2,
            SUPP_EMAIL,
                   ROW_NUMBER() OVER (PARTITION BY SUPPLIER_NAME ORDER BY SUPP_CONTACT_NAME) AS rn
            FROM BCM_ORDER_MGT
        )
        WHERE rn = 1;

        -- Insert data into orders table, using supplier_id from inserted suppliers
        INSERT INTO orders (order_ref, order_date, supplier_id, order_total_amount,order_line_amount,order_description, order_status)
        SELECT distinct ORDER_REF, TO_DATE(ORDER_DATE, 'DD-MM-YYYY'), s.supplier_id,
              	 		TO_NUMBER(REPLACE(REPLACE(REPLACE(REPLACE(ORDER_TOTAL_AMOUNT, 'I', '1'), 'o', '0'), ',', ''),'S','5') DEFAULT 0 ON CONVERSION ERROR) AS ORDER_TOTAL_AMOUNT,	
     					TO_NUMBER(REPLACE(REPLACE(REPLACE(REPLACE(ORDER_LINE_AMOUNT, 'I', '1'), 'o', '0'), ',', ''),'S','5') DEFAULT 0 ON CONVERSION ERROR) AS ORDER_LINE_AMOUNT, 
     					ORDER_DESCRIPTION, ORDER_STATUS
        FROM BCM_ORDER_MGT mt
        JOIN suppliers s ON s.SUPPLIER_NAME = mt.SUPPLIER_NAME ORDER BY ORDER_REF;

        -- Insert data into invoices table, using order_id from inserted orders
        INSERT INTO invoices (invoice_reference, invoice_date, order_id, invoice_status,
                    invoice_hold_reason, invoice_amount, invoice_description)
        SELECT INVOICE_REFERENCE, TO_DATE(INVOICE_DATE, 'DD-MM-YYYY'), o.order_id,
               INVOICE_STATUS, INVOICE_HOLD_REASON, 
     		   TO_NUMBER(REPLACE(REPLACE(REPLACE(REPLACE(INVOICE_AMOUNT, 'I', '1'), 'o', '0'), ',', ''),'S','5') DEFAULT 0 ON CONVERSION ERROR) AS INVOICE_AMOUNT,
               INVOICE_DESCRIPTION
        FROM BCM_ORDER_MGT mt
        JOIN orders o ON o.order_ref = mt.ORDER_REF AND o.order_description = mt.ORDER_DESCRIPTION
        WHERE INVOICE_REFERENCE IS NOT NULL ORDER BY o.order_ref;

        -- Commit changes if successful
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback changes in case of errors
            ROLLBACK;
            -- Log or raise the exception for analysis
            DBMS_OUTPUT.PUT_LINE('Error during migration: ' || SQLCODE || ' - ' || SQLERRM);
    END;
END;