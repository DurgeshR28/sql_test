CREATE OR REPLACE PROCEDURE get_order_data(p_order_data OUT SYS_REFCURSOR)
AS
BEGIN
  OPEN p_order_data FOR
    SELECT 
      s.supplier_city,
      INITCAP(s.supplier_name) AS supplier_name,
      TO_CHAR(o.order_date, 'YYYY-DD') AS order_period,
      SUBSTR(o.order_ref, INSTR(o.order_ref, '0') + 1) AS order_ref,
      o.order_line_amount,
      TO_CHAR(o.order_total_amount, '99,999,990.00') AS order_total_amount,
      TO_CHAR(
        (
          SELECT SUM(invoice_amount)
          FROM invoices
          WHERE invoice_reference LIKE '%' || o.order_ref || '%'
        ), '99,999,990.00'
      ) AS invoice_total_amount,
      (
        SELECT CASE
                 WHEN EXISTS (
                   SELECT 1
                   FROM invoices
                   WHERE invoice_status LIKE '%Pending%'
                   AND invoice_reference LIKE '%' || o.order_ref || '%'
                 )
                 THEN 'To follow up'
                 WHEN EXISTS (
                   SELECT 1
                   FROM invoices
                   WHERE invoice_status IS NULL
                   AND invoice_reference LIKE '%' || o.order_ref || '%'
                 )
                 THEN 'To verify'
                 ELSE 'No Action'
               END AS action_status
         FROM dual
      ) AS action
    FROM orders o
    JOIN suppliers s ON o.supplier_id = s.supplier_id
    WHERE o.order_total_amount IS NOT NULL
    ORDER BY o.order_date DESC, s.supplier_city ASC;
END;

