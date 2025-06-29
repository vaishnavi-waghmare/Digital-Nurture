-- Exercise 6: Cursors

-- Scenario 1: Generate monthly statements for all customers
SET SERVEROUTPUT ON;
DECLARE
    -- Cursor to fetch all customers
    CURSOR c_customers IS
        SELECT c.CustomerID, c.Name, c.Balance
        FROM Customers c;
    
    -- Cursor to fetch transactions for a specific customer in the current month
    CURSOR c_transactions(p_cust_id NUMBER) IS
        SELECT t.TransactionID, t.TransactionDate, t.Amount, t.TransactionType, a.AccountID
        FROM Transactions t
        JOIN Accounts a ON t.AccountID = a.AccountID
        WHERE a.CustomerID = p_cust_id
        AND t.TransactionDate BETWEEN TRUNC(SYSDATE, 'MM') AND LAST_DAY(SYSDATE)
        ORDER BY t.TransactionDate;
    
    v_transaction_count NUMBER;
    v_total_deposits NUMBER := 0;
    v_total_withdrawals NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== MONTHLY STATEMENTS - ' || TO_CHAR(SYSDATE, 'MONTH YYYY') || ' ===');
    
    -- Loop through all customers
    FOR cust_rec IN c_customers LOOP
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Statement for: ' || cust_rec.Name || ' (ID: ' || cust_rec.CustomerID || ')');
        DBMS_OUTPUT.PUT_LINE('Current Balance: $' || TO_CHAR(cust_rec.Balance, '999,999.99'));
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
        DBMS_OUTPUT.PUT_LINE('Transactions:');
        DBMS_OUTPUT.PUT_LINE('ID | Date | Account | Type | Amount');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
        
        -- Reset counters for this customer
        v_transaction_count := 0;
        v_total_deposits := 0;
        v_total_withdrawals := 0;
        
        -- Loop through transactions for this customer in the current month
        FOR trans_rec IN c_transactions(cust_rec.CustomerID) LOOP
            DBMS_OUTPUT.PUT_LINE(trans_rec.TransactionID || ' | ' ||
                                TO_CHAR(trans_rec.TransactionDate, 'DD-MON-YYYY') || ' | ' ||
                                trans_rec.AccountID || ' | ' ||
                                trans_rec.TransactionType || ' | $' ||
                                TO_CHAR(trans_rec.Amount, '999,999.99'));
            
            -- Update counters
            v_transaction_count := v_transaction_count + 1;
            
            IF trans_rec.TransactionType = 'Deposit' THEN
                v_total_deposits := v_total_deposits + trans_rec.Amount;
            ELSIF trans_rec.TransactionType = 'Withdrawal' THEN
                v_total_withdrawals := v_total_withdrawals + trans_rec.Amount;
            END IF;
        END LOOP;
        
        -- Print summary for this customer
        IF v_transaction_count = 0 THEN
            DBMS_OUTPUT.PUT_LINE('No transactions in the current month.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('----------------------------------------');
            DBMS_OUTPUT.PUT_LINE('Total Transactions: ' || v_transaction_count);
            DBMS_OUTPUT.PUT_LINE('Total Deposits: $' || TO_CHAR(v_total_deposits, '999,999.99'));
            DBMS_OUTPUT.PUT_LINE('Total Withdrawals: $' || TO_CHAR(v_total_withdrawals, '999,999.99'));
            DBMS_OUTPUT.PUT_LINE('Net Change: $' || TO_CHAR(v_total_deposits - v_total_withdrawals, '999,999.99'));
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
        DBMS_OUTPUT.PUT_LINE('');
    END LOOP;
    
    DBMS_OUTPUT.PUT_LINE('=== END OF MONTHLY STATEMENTS ===');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error generating statements: ' || SQLERRM);
END;
/

-- Scenario 2: Apply annual fee to all accounts
SET SERVEROUTPUT ON;
DECLARE
    -- Cursor to fetch all accounts
    CURSOR c_accounts IS
        SELECT AccountID, AccountType, Balance
        FROM Accounts;
    
    v_annual_fee NUMBER := 50; -- Fixed annual fee of $50
    v_fee_applied NUMBER := 0;
    v_fee_waived NUMBER := 0;
    v_min_balance NUMBER := 1000; -- Minimum balance to waive fee
    e_insufficient_funds EXCEPTION;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== APPLYING ANNUAL MAINTENANCE FEES ===');
    
    -- Loop through all accounts
    FOR acc_rec IN c_accounts LOOP
        BEGIN
            -- Check if fee can be waived (balance > minimum balance)
            IF acc_rec.Balance >= v_min_balance THEN
                DBMS_OUTPUT.PUT_LINE('Fee waived for Account ' || acc_rec.AccountID || 
                                    ' (' || acc_rec.AccountType || ') - Balance: $' || 
                                    TO_CHAR(acc_rec.Balance, '999,999.99') || 
                                    ' exceeds minimum balance.');
                v_fee_waived := v_fee_waived + 1;
            ELSIF acc_rec.Balance < v_annual_fee THEN
                -- If balance is less than fee, log error but don't apply fee
                RAISE e_insufficient_funds;
            ELSE
                -- Apply the fee
                UPDATE Accounts
                SET Balance = Balance - v_annual_fee,
                    LastModified = SYSDATE
                WHERE AccountID = acc_rec.AccountID;
                
                DBMS_OUTPUT.PUT_LINE('Fee of $' || v_annual_fee || 
                                    ' applied to Account ' || acc_rec.AccountID || 
                                    ' (' || acc_rec.AccountType || ')' ||
                                    '. New Balance: $' || TO_CHAR(acc_rec.Balance - v_annual_fee, '999,999.99'));
                v_fee_applied := v_fee_applied + 1;
            END IF;
        EXCEPTION
            WHEN e_insufficient_funds THEN
                DBMS_OUTPUT.PUT_LINE('WARNING: Insufficient funds in Account ' || acc_rec.AccountID || 
                                    '. Fee not applied. Current Balance: $' || TO_CHAR(acc_rec.Balance, '999,999.99'));
        END;
    END LOOP;
    
    -- Commit the changes
    COMMIT;
    
    -- Print summary
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Annual Fee Summary:');
    DBMS_OUTPUT.PUT_LINE('Fees Applied: ' || v_fee_applied || ' accounts');
    DBMS_OUTPUT.PUT_LINE('Fees Waived: ' || v_fee_waived || ' accounts');
    DBMS_OUTPUT.PUT_LINE('Total Fees Collected: $' || TO_CHAR(v_fee_applied * v_annual_fee, '999,999.99'));
    DBMS_OUTPUT.PUT_LINE('=== ANNUAL FEE PROCESSING COMPLETE ===');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error applying annual fees: ' || SQLERRM);
END;
/

-- Scenario 3: Update loan interest rates based on a new policy
SET SERVEROUTPUT ON;
DECLARE
    -- Cursor to fetch all loans
    CURSOR c_loans IS
        SELECT l.LoanID, l.InterestRate, l.LoanAmount, l.StartDate, l.EndDate, c.CustomerID, c.Name
        FROM Loans l
        JOIN Customers c ON l.CustomerID = c.CustomerID;
    
    v_new_rate NUMBER;
    v_updated_count NUMBER := 0;
    v_base_rate NUMBER := 3.5; -- Base interest rate
    v_vip_discount NUMBER := 0.5; -- Discount for VIP customers
    v_large_loan_discount NUMBER := 0.25; -- Discount for loans over $10,000
    v_long_term_premium NUMBER := 0.75; -- Premium for loans longer than 5 years
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== UPDATING LOAN INTEREST RATES ===');
    DBMS_OUTPUT.PUT_LINE('Base Rate: ' || v_base_rate || '%');
    DBMS_OUTPUT.PUT_LINE('VIP Discount: ' || v_vip_discount || '%');
    DBMS_OUTPUT.PUT_LINE('Large Loan Discount: ' || v_large_loan_discount || '%');
    DBMS_OUTPUT.PUT_LINE('Long Term Premium: ' || v_long_term_premium || '%');
    DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    
    -- Loop through all loans
    FOR loan_rec IN c_loans LOOP
        -- Start with base rate
        v_new_rate := v_base_rate;
        
        -- Check if customer is VIP
        DECLARE
            v_is_vip BOOLEAN := FALSE;
        BEGIN
            SELECT IsVIP INTO v_is_vip
            FROM Customers
            WHERE CustomerID = loan_rec.CustomerID;
            
            -- Apply VIP discount if applicable
            IF v_is_vip THEN
                v_new_rate := v_new_rate - v_vip_discount;
                DBMS_OUTPUT.PUT_LINE('Customer ' || loan_rec.Name || ' is VIP: -' || v_vip_discount || '%');
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                -- If IsVIP column doesn't exist or other error, continue without discount
                NULL;
        END;
        
        -- Apply large loan discount if applicable
        IF loan_rec.LoanAmount > 10000 THEN
            v_new_rate := v_new_rate - v_large_loan_discount;
            DBMS_OUTPUT.PUT_LINE('Loan ' || loan_rec.LoanID || ' is a large loan: -' || v_large_loan_discount || '%');
        END IF;
        
        -- Apply long-term premium if applicable (loan duration > 5 years)
        IF MONTHS_BETWEEN(loan_rec.EndDate, loan_rec.StartDate) > 60 THEN
            v_new_rate := v_new_rate + v_long_term_premium;
            DBMS_OUTPUT.PUT_LINE('Loan ' || loan_rec.LoanID || ' is a long-term loan: +' || v_long_term_premium || '%');
        END IF;
        
        -- Ensure rate is not negative
        IF v_new_rate < 1 THEN
            v_new_rate := 1; -- Minimum rate of 1%
        END IF;
        
        -- Update loan interest rate
        UPDATE Loans
        SET InterestRate = v_new_rate
        WHERE LoanID = loan_rec.LoanID;
        
        v_updated_count := v_updated_count + 1;
        
        DBMS_OUTPUT.PUT_LINE('Loan ID ' || loan_rec.LoanID || ' for ' || loan_rec.Name || 
                           ': Old Rate ' || loan_rec.InterestRate || '% → New Rate ' || v_new_rate || '%');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------');
    END LOOP;
    
    -- Commit the changes
    COMMIT;
    
    -- Print summary
    DBMS_OUTPUT.PUT_LINE('Interest rate update completed for ' || v_updated_count || ' loan(s).');
    DBMS_OUTPUT.PUT_LINE('=== LOAN INTEREST RATE UPDATE COMPLETE ===');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error updating loan interest rates: ' || SQLERRM);
END;
/ 