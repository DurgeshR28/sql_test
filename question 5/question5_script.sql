CREATE OR REPLACE PROCEDURE get_order_median_value(p_order_data OUT SYS_REFCURSOR)
AS
BEGIN
  OPEN p_order_data FOR
    SELECT supplier_name,
           TO_CHAR(order_total_amount, '99,999,990.00') AS order_total_amount,
           order_status,
           order_date,
           order_ref,
           median_amount,
           invoice_references
    FROM (
      SELECT UPPER(s.supplier_name) AS supplier_name,
             o.order_total_amount,
             o.order_status,
             TO_CHAR(o.order_date, 'DD-MON-YYYY') AS order_date,
             SUBSTR(o.order_ref, INSTR(o.order_ref, '0') + 1) AS order_ref,
             (
               SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY order_total_amount)
               FROM orders
               WHERE order_total_amount IS NOT NULL
             ) AS median_amount,
             (
               SELECT LISTAGG(invoice_reference, '|') WITHIN GROUP (ORDER BY invoice_reference DESC)
               FROM invoices
               WHERE invoice_reference LIKE '%' || o.order_ref || '%'
             ) AS invoice_references
      FROM orders o
      LEFT JOIN suppliers s ON o.supplier_id = s.supplier_id
      LEFT JOIN invoices i ON o.order_id = i.order_id
      WHERE o.order_total_amount IS NOT NULL
    )
    WHERE order_total_amount = (
      SELECT order_total_amount
      FROM orders
      WHERE order_total_amount >= median_amount
      ORDER BY order_total_amount
      FETCH FIRST 1 ROWS ONLY
    );
END;

