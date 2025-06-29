-- Exercise 1: Control Structures

-- Scenario 1: Apply discount to loan interest rates for customers above 60
SET SERVEROUTPUT ON;
DECLARE
    v_customer_id Customers.CustomerID%TYPE;
    v_dob Customers.DOB%TYPE;
    v_age NUMBER;
    v_current_rate Loans.InterestRate%TYPE;
    
    CURSOR c_seniors IS
        SELECT c.CustomerID, c.DOB, l.LoanID, l.InterestRate
        FROM Customers c
        JOIN Loans l ON c.CustomerID = l.CustomerID;
BEGIN
    FOR senior_rec IN c_seniors LOOP
        -- Calculate age
        v_age := FLOOR(MONTHS_BETWEEN(SYSDATE, senior_rec.DOB) / 12);
        
        -- Check if the customer is above 60
        IF v_age > 60 THEN
            -- Apply 1% discount to the current loan interest rate
            UPDATE Loans
            SET InterestRate = InterestRate - 1
            WHERE LoanID = senior_rec.LoanID;
            
            DBMS_OUTPUT.PUT_LINE('Applied discount to customer ID ' || senior_rec.CustomerID || 
                                ', New interest rate: ' || (senior_rec.InterestRate - 1));
        END IF;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Interest rate discounts applied successfully.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

-- Scenario 2: Set VIP flag based on balance
SET SERVEROUTPUT ON;
DECLARE
    CURSOR c_high_balance IS
        SELECT CustomerID, Balance
        FROM Customers;
    v_vip_threshold NUMBER := 10000;
BEGIN
    FOR cust_rec IN c_high_balance LOOP
        IF cust_rec.Balance > v_vip_threshold THEN
            -- Set VIP flag to TRUE
            UPDATE Customers
            SET IsVIP = TRUE
            WHERE CustomerID = cust_rec.CustomerID;
            
            DBMS_OUTPUT.PUT_LINE('Customer ID ' || cust_rec.CustomerID || 
                                ' promoted to VIP status with balance: $' || cust_rec.Balance);
        END IF;
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('VIP status updates completed successfully.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;
/

-- Scenario 3: Send reminders for loans due in the next 30 days
SET SERVEROUTPUT ON;
DECLARE
    CURSOR c_due_loans IS
        SELECT c.CustomerID, c.Name, l.LoanID, l.EndDate
        FROM Customers c
        JOIN Loans l ON c.CustomerID = l.CustomerID
        WHERE l.EndDate BETWEEN SYSDATE AND SYSDATE + 30;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== LOAN PAYMENT REMINDERS ===');
    
    FOR loan_rec IN c_due_loans LOOP
        DBMS_OUTPUT.PUT_LINE('Dear ' || loan_rec.Name || ',');
        DBMS_OUTPUT.PUT_LINE('This is a friendly reminder that your loan (ID: ' || loan_rec.LoanID || 
                            ') is due on ' || TO_CHAR(loan_rec.EndDate, 'DD-MON-YYYY') || '.');
        DBMS_OUTPUT.PUT_LINE('Please ensure timely payment to avoid late fees.');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('=== END OF REMINDERS ===');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred while processing reminders: ' || SQLERRM);
END;
/ 