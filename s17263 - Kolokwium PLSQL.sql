-- Odpowiedz do zad 1 --

CREATE OR REPLACE PROCEDURE zatowarowanie (v_nazwa VARCHAR, v_stan INT, v_cena NUMBER)
IS
    v_nazwa_i_cena NUMBER;
    v_max_indeks NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_nazwa_i_cena FROM magazyn WHERE nazwa = v_nazwa AND cena = v_cena;
    SELECT MAX(idpozycji) INTO v_max_indeks FROM magazyn;
    IF v_nazwa_i_cena > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Produkt istnieje w bazie, zwiększam stan magazynowy');
        UPDATE MAGAZYN SET stan = stan + v_stan WHERE nazwa = v_nazwa AND cena = v_cena;       
    ELSE
        DBMS_OUTPUT.PUT_LINE('Produkt nie istnieje w bazie, dodaje pozycje');
        INSERT INTO MAGAZYN VALUES (v_max_indeks + 1, v_nazwa, v_cena, v_stan);       
    END IF;
END;

-- Odpowiedz do zad 2 --

CREATE OR REPLACE TRIGGER zad_2
BEFORE UPDATE OR INSERT ON magazyn
FOR EACH ROW
BEGIN
    IF :new.stan < 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Stan magazynowy nie moze byc ujemny');
    ELSIF :new.cena > :old.cena*1.05 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cena nie moze wzrosnac o wiecej niz 5%');
    ELSIF :new.cena < 1 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Cena nie moze byc ujemna lub wynosic 0');
    END IF;
END;