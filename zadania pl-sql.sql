SET SERVEROUTPUT ON;

-- PL/SQL - Zestaw 1

-- Zad 1 -----------------------------------------------------------------------

DECLARE
    v_kolumny NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_kolumny FROM EMP;
    DBMS_OUTPUT.PUT_LINE('W tabeli jest ' || v_kolumny || ' rekordow');
END;

-- Zad 2 -----------------------------------------------------------------------
DECLARE
    v_kolumny NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_kolumny FROM EMP;
    IF v_kolumny < 16 THEN
        DBMS_OUTPUT.PUT_LINE('Dodanie rekordu');
        INSERT INTO EMP VALUES (9999, 'KOWALSKI', 'CLERK', 7902, TO_DATE('1980-12-17','YYYY-MM-DD'),  800, NULL, 20);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Nie dodano rekordu');
    END IF;
END;

-- Zad 3 -----------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE wstawianie_dzialu (v_nr_dzialu NUMBER, v_nazwa VARCHAR, v_lokalizacja VARCHAR)
IS
    v_update BOOLEAN := TRUE;
    v_temp dept.deptno%TYPE;
    CURSOR sprawdzanie_indeksu IS SELECT DEPTNO FROM dept;
BEGIN
    OPEN sprawdzanie_indeksu;
    LOOP
        FETCH sprawdzanie_indeksu INTO v_temp;
        EXIT WHEN sprawdzanie_indeksu%NOTFOUND;
        IF v_temp = v_nr_dzialu THEN
            v_update := FALSE;
            DBMS_OUTPUT.PUT_LINE('Departament o podanej nazwie juz istnieje');
        END IF;
    END LOOP;
    CLOSE sprawdzanie_indeksu;
    IF v_update THEN
        INSERT INTO dept VALUES (v_nr_dzialu, v_nazwa, v_lokalizacja);
        DBMS_OUTPUT.PUT_LINE('Dodano departament');
    END IF;
END;

-- Uruchomienie
BEGIN
    wstawianie_dzialu(50, 'DESIGN', 'WARSAW');
END;

-- Select pomocniczy
SELECT * FROM DEPT;

-- Zad 4 -----------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE wstawianie_pracownika (v_nr_dzialu NUMBER, v_nazwisko VARCHAR)
IS
    v_ilosc_kolumn NUMBER;
    v_min_sal NUMBER;
    v_max_empno NUMBER;
    v_dept_nie_istnieje EXCEPTION;
BEGIN
    SELECT COUNT(deptno) INTO v_ilosc_kolumn FROM dept WHERE deptno = v_nr_dzialu;
    IF v_ilosc_kolumn > 0 THEN
        SELECT MIN(sal) INTO v_min_sal FROM emp WHERE deptno = v_nr_dzialu;
        SELECT MAX(empno) INTO v_max_empno FROM emp WHERE deptno = v_nr_dzialu;
        IF v_max_empno IS NULL THEN
            v_max_empno := 0;
            v_min_sal := 0;
        END IF;
        v_max_empno := v_max_empno + 1;
        INSERT INTO EMP VALUES (v_max_empno, v_nazwisko, 'CLERK', 7902, TO_DATE('1980-12-17','YYYY-MM-DD'),  v_min_sal, 300, v_nr_dzialu);
    ELSE
        RAISE v_dept_nie_istnieje;
    END IF;
EXCEPTION
    WHEN v_dept_nie_istnieje THEN
        DBMS_OUTPUT.PUT_LINE('Departament nie istnieje');
END;

BEGIN
    wstawianie_pracownika(30, 'G');
END;

-- Zad 5 -----------------------------------------------------------------------

CREATE TABLE MAGAZYN(IdPozycji NUMBER(4), Nazwa VARCHAR2(14), Ilosc NUMBER(4), CONSTRAINT MAGAZYN_PK PRIMARY KEY (IdPozycji));

INSERT INTO MAGAZYN VALUES (1,  'Tysiac', 1000);
INSERT INTO MAGAZYN VALUES (2,  'Osiem', 8);
INSERT INTO MAGAZYN VALUES (3,  'Piecdziesiat', 50);
INSERT INTO MAGAZYN VALUES (4,  'Osiemset', 800);

DECLARE
    v_max NUMBER;
    v_row magazyn%ROWTYPE;
    v_wyjatek EXCEPTION;
BEGIN
    SELECT MAX(ilosc) INTO v_max FROM magazyn;
    IF v_max > 5 THEN
        UPDATE magazyn SET ilosc=5 WHERE ilosc=v_max;
    ELSE
        RAISE v_wyjatek;
    END IF;
EXCEPTION
    WHEN v_wyjatek THEN
        DBMS_OUTPUT.PUT_LINE('Za mala ilosc do zmiejszenia'); 
END;

SELECT * FROM MAGAZYN;

-- PL/SQL - Kursory

-- Zad 1 -----------------------------------------------------------------------

DECLARE
    CURSOR sprawdzanie_pensji IS SELECT empno, sal FROM emp;
    v_sal emp.sal%type;
    v_empno emp.empno%type;
BEGIN
    OPEN sprawdzanie_pensji;
    LOOP
        FETCH sprawdzanie_pensji INTO v_empno, v_sal;
        EXIT WHEN sprawdzanie_pensji%NOTFOUND;
        IF v_sal < 1000 THEN
            UPDATE emp SET sal = sal * 1.1 WHERE empno = v_empno;
            DBMS_OUTPUT.PUT_LINE('Pracownik nr. ' || v_empno || ' dostal zwiekszona pensje');
        ELSIF v_sal > 1500 THEN
            UPDATE emp SET sal = sal * 0.9 WHERE empno = v_empno;
            DBMS_OUTPUT.PUT_LINE('Pracownik nr. ' || v_empno || ' dostal zmiejszona pensje');
        END IF;
    END LOOP;
    CLOSE sprawdzanie_pensji;
END;

-- Zad 2 -----------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE zmiana_pensji (v_min NUMBER, v_max NUMBER)
IS
    CURSOR sprawdzanie_pensji IS SELECT empno, sal FROM emp;
    v_sal emp.sal%type;
    v_empno emp.empno%type;
BEGIN
    OPEN sprawdzanie_pensji;
    LOOP
        FETCH sprawdzanie_pensji INTO v_empno, v_sal;
        EXIT WHEN sprawdzanie_pensji%NOTFOUND;
        IF v_sal < v_min THEN
            UPDATE emp SET sal = sal * 1.1 WHERE empno = v_empno;
            DBMS_OUTPUT.PUT_LINE('Pracownik nr. ' || v_empno || ' dostal zwiekszona pensje');
        ELSIF v_max > 1500 THEN
            UPDATE emp SET sal = sal * 0.9 WHERE empno = v_empno;
            DBMS_OUTPUT.PUT_LINE('Pracownik nr. ' || v_empno || ' dostal zmiejszona pensje');
        END IF;
    END LOOP;
    CLOSE sprawdzanie_pensji;
END;

BEGIN
    zmiana_pensji(1000,1500);
END;

-- Zad 3 -----------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE dodanie_prowizji (v_deptno NUMBER)
IS
    CURSOR sprawdzanie_pensji IS SELECT empno, sal FROM emp;
    v_sal emp.sal%type;
    v_empno emp.empno%type;
    v_avg NUMBER;
BEGIN
    SELECT AVG(SAL) INTO v_avg FROM EMP WHERE DEPTNO = v_deptno;
    IF v_avg IS NOT NULL THEN
        OPEN sprawdzanie_pensji;
        LOOP
            FETCH sprawdzanie_pensji INTO v_empno, v_sal;
            EXIT WHEN sprawdzanie_pensji%NOTFOUND;
            IF v_sal < v_avg THEN
                UPDATE emp SET comm = sal * 1.05;
            END IF;
        END LOOP;
        CLOSE sprawdzanie_pensji;
    END IF;
END;
    
BEGIN
    dodanie_prowizji(10);
END;
    
SELECT * FROM EMP;
    
-- Zad 4 -----------------------------------------------------------------------
    
CREATE TABLE MAGAZYN(IdPozycji NUMBER(4), Nazwa VARCHAR2(14), Ilosc NUMBER(4), CONSTRAINT MAGAZYN_PK PRIMARY KEY (IdPozycji));

INSERT INTO MAGAZYN VALUES (1,  'Tysiac', 1000);
INSERT INTO MAGAZYN VALUES (2,  'Osiem', 8);
INSERT INTO MAGAZYN VALUES (3,  'Piecdziesiat', 50);
INSERT INTO MAGAZYN VALUES (4,  'Osiemset', 800);

DECLARE
    v_max NUMBER;
    v_row magazyn%ROWTYPE;
    v_wyjatek EXCEPTION;
BEGIN
    SELECT MAX(ilosc) INTO v_max FROM magazyn;
    IF v_max > 5 THEN
        UPDATE magazyn SET ilosc=8 WHERE ilosc=5;
    ELSE
        RAISE v_wyjatek;
    END IF;
EXCEPTION
    WHEN v_wyjatek THEN
        DBMS_OUTPUT.PUT_LINE('Za mala ilosc do zmiejszenia'); 
END;

-- Zad 5 -----------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE stan_magazynowy (v_ilosc NUMBER)
IS
    v_max NUMBER;
    v_row magazyn%ROWTYPE;
    v_wyjatek EXCEPTION;
BEGIN
    SELECT MAX(ilosc) INTO v_max FROM magazyn;
    IF v_max > v_ilosc THEN
        UPDATE magazyn SET ilosc=v_ilosc WHERE ilosc=v_max;
    ELSE
        RAISE v_wyjatek;
    END IF;
EXCEPTION
    WHEN v_wyjatek THEN
        DBMS_OUTPUT.PUT_LINE('Za mala ilosc do zmiejszenia'); 
END;

BEGIN
 stan_magazynowy(3);
END;

SELECT * FROM MAGAZYN;

-- PL/SQL - Wyzwalacze

-- Zad 1 -----------------------------------------------------------------------

CREATE OR REPLACE TRIGGER usuwanie
BEFORE DELETE ON emp
FOR EACH ROW
BEGIN
    RAISE_APPLICATION_ERROR(-20001, 'Trigger, zakaz usuwania z emp');
END;

DROP TRIGGER usuwanie;

-- Zad 2 -----------------------------------------------------------------------

CREATE OR REPLACE TRIGGER modyfikacja
BEFORE INSERT OR UPDATE ON emp
FOR EACH ROW
BEGIN
    IF :new.sal > 1000 THEN
        DBMS_OUTPUT.PUT_LINE('Zarobki ustawiono na ' || :new.sal);
    ELSE
        RAISE_APPLICATION_ERROR(-20001, 'Nowa wartosc jest mniejsza od 1000');
    END IF;
END;

DROP TRIGGER modyfikacja;

-- Zad 3 -----------------------------------------------------------------------

CREATE TABLE budzet (wartosc INT NOT NULL);

INSERT INTO budzet (wartosc) SELECT SUM(sal) FROM emp;

SELECT * FROM budzet;

CREATE OR REPLACE TRIGGER aktualizacja
AFTER INSERT OR UPDATE OR DELETE ON emp
FOR EACH ROW
BEGIN
    INSERT INTO budzet (wartosc) SELECT SUM(sal) FROM emp;
    DBMS_OUTPUT.PUT_LINE('Przeliczono table budzet');
END;

DROP TRIGGER aktualizacja;

-- Zad 4 -----------------------------------------------------------------------

CREATE OR REPLACE TRIGGER zad_4
BEFORE INSERT ON emp
FOR EACH ROW
DECLARE
    v_ilosc NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_ilosc FROM emp WHERE Ename = :new.Ename;
    IF v_ilosc > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Osoba o danym nazwisku juz istnieje');
    END IF;
END;

DROP TRIGGER zad_4;

-- Zad 5 -----------------------------------------------------------------------

CREATE OR REPLACE TRIGGER zad_5
BEFORE UPDATE OR DELETE ON emp
FOR EACH ROW
BEGIN
    IF :old.sal > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nie mozna usunac osoby zarabiajacej wiecej niz 0');
    ELSIF :old.ename != :new.ename THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nie mozna zmieniac nazwiska');
    END IF;
END;

DROP TRIGGER zad_5;

-- Zad 6 -----------------------------------------------------------------------

CREATE OR REPLACE TRIGGER zad_6
BEFORE UPDATE OR DELETE ON emp
FOR EACH ROW
BEGIN
    IF :old.sal>:new.sal THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nie moze zarabiac mniej');
    ELSIF DELETING THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nie mozna usunac pracownika');
    END IF; 
END;

DROP TRIGGER zad_6;