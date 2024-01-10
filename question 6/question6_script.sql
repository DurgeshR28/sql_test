CREATE OR REPLACE PROCEDURE get_supplier_orders(p_orders_data OUT SYS_REFCURSOR)
AS
BEGIN
  OPEN p_orders_data FOR
    SELECT
      TO_CHAR(o.order_date, 'MON-YYYY') AS months,
      s.supplier_name,
      s.supplier_contact_name,
      s.supplier_contact_number,
      s.supplier_contact_number2,
      (
        SELECT COUNT(order_line_amount)
        FROM orders
        WHERE order_ref LIKE '%' || o.order_ref || '%'
      ) AS total_orders,
      TO_CHAR(order_total_amount, '99,999,990.00') AS order_total_amount
    FROM suppliers s
    JOIN orders o ON s.supplier_id = o.supplier_id
    WHERE o.order_total_amount IS NOT NULL
    AND o.order_date BETWEEN TO_DATE('2023-01-01', 'YYYY-MM-DD') AND TO_DATE('2023-08-31', 'YYYY-MM-DD');
END;

