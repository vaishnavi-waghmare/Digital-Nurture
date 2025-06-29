-- Exercise 4: Functions

-- Scenario 1: Calculate the age of customers for eligibility checks
CREATE OR REPLACE FUNCTION CalculateAge(
    p_dob IN DATE
) RETURN NUMBER IS
    v_age NUMBER;
BEGIN
    -- Calculate age based on date of birth and current date
    v_age := FLOOR(MONTHS_BETWEEN(SYSDATE, p_dob) / 12);
    
    RETURN v_age;
EXCEPTION
    WHEN OTHERS THEN
        -- Log error and return NULL
        DBMS_OUTPUT.PUT_LINE('Error calculating age: ' || SQLERRM);
        RETURN NULL;
END CalculateAge;
/

-- Test the CalculateAge function
SET SERVEROUTPUT ON;
DECLARE
    v_test_dob DATE := TO_DATE('1980-06-15', 'YYYY-MM-DD');
    v_age NUMBER;
BEGIN
    v_age := CalculateAge(v_test_dob);
    DBMS_OUTPUT.PUT_LINE('Age for DOB ' || TO_CHAR(v_test_dob, 'DD-MON-YYYY') || ': ' || v_age);
END;
/

-- Scenario 2: Compute the monthly installment for a loan
CREATE OR REPLACE FUNCTION CalculateMonthlyInstallment(
    p_loan_amount IN NUMBER,
    p_interest_rate IN NUMBER,
    p_years IN NUMBER
) RETURN NUMBER IS
    v_monthly_rate NUMBER;
    v_num_payments NUMBER;
    v_installment NUMBER;
BEGIN
    -- Input validation
    IF p_loan_amount <= 0 OR p_interest_rate < 0 OR p_years <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Invalid input parameters.');
    END IF;
    
    -- Convert annual interest rate to monthly rate (percentage to decimal)
    v_monthly_rate := p_interest_rate / (12 * 100);
    
    -- Calculate number of payments
    v_num_payments := p_years * 12;
    
    -- Calculate monthly installment using the loan amortization formula
    -- Formula: PMT = P * r * (1 + r)^n / ((1 + r)^n - 1)
    -- Where: PMT = monthly payment, P = principal, r = monthly interest rate, n = number of payments
    v_installment := p_loan_amount * v_monthly_rate * POWER(1 + v_monthly_rate, v_num_payments) 
                    / (POWER(1 + v_monthly_rate, v_num_payments) - 1);
    
    RETURN ROUND(v_installment, 2);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error calculating monthly installment: ' || SQLERRM);
        RETURN NULL;
END CalculateMonthlyInstallment;
/

-- Test the CalculateMonthlyInstallment function
SET SERVEROUTPUT ON;
DECLARE
    v_loan_amount NUMBER := 10000;
    v_interest_rate NUMBER := 5;  -- 5% annual interest rate
    v_years NUMBER := 3;         -- 3-year loan term
    v_installment NUMBER;
BEGIN
    v_installment := CalculateMonthlyInstallment(v_loan_amount, v_interest_rate, v_years);
    
    DBMS_OUTPUT.PUT_LINE('Loan Amount: $' || v_loan_amount);
    DBMS_OUTPUT.PUT_LINE('Interest Rate: ' || v_interest_rate || '%');
    DBMS_OUTPUT.PUT_LINE('Loan Term: ' || v_years || ' years');
    DBMS_OUTPUT.PUT_LINE('Monthly Installment: $' || TO_CHAR(v_installment, '999,999.99'));
END;
/

-- Scenario 3: Check if a customer has sufficient balance before making a transaction
CREATE OR REPLACE FUNCTION HasSufficientBalance(
    p_account_id IN NUMBER,
    p_amount IN NUMBER
) RETURN BOOLEAN IS
    v_balance NUMBER;
BEGIN
    -- Input validation
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Amount must be positive.');
    END IF;
    
    -- Get account balance
    SELECT Balance INTO v_balance
    FROM Accounts
    WHERE AccountID = p_account_id;
    
    -- Check if balance is sufficient
    RETURN v_balance >= p_amount;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20003, 'Account not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error checking balance: ' || SQLERRM);
        RETURN FALSE;
END HasSufficientBalance;
/

-- Test the HasSufficientBalance function
SET SERVEROUTPUT ON;
DECLARE
    v_account_id NUMBER := 1;
    v_amount NUMBER := 500;
    v_sufficient BOOLEAN;
BEGIN
    v_sufficient := HasSufficientBalance(v_account_id, v_amount);
    
    IF v_sufficient THEN
        DBMS_OUTPUT.PUT_LINE('Account ' || v_account_id || ' has sufficient balance for $' || v_amount);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Account ' || v_account_id || ' does NOT have sufficient balance for $' || v_amount);
    END IF;
END;
/ 