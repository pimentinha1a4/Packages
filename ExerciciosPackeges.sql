-- Pacote PKG_ALUNO

1.Procedure de exclusão de aluno:

CREATE OR REPLACE PROCEDURE excluir_aluno(p_id_aluno IN NUMBER) IS
BEGIN
    
    DELETE FROM aluno WHERE id_aluno = p_id_aluno;
    
    COMMIT; 
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aluno com ID ' || p_id_aluno || ' não encontrado.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro inesperado: ' || SQLERRM);
        ROLLBACK; -- Desfaz a transação em caso de erro
END;
/

2.Cursor de listagem de alunos maiores de 18 anos:

CREATE OR REPLACE PROCEDURE listar_alunos_maiores_de_18 IS
    CURSOR c_alunos_maiores_18 IS
        SELECT nome, data_nascimento
        FROM aluno
        WHERE data_nascimento <= ADD_MONTHS(SYSDATE, -12 * 18); 

    v_aluno c_alunos_maiores_18%ROWTYPE; 
BEGIN
    OPEN c_alunos_maiores_18;
    LOOP
        FETCH c_alunos_maiores_18 INTO v_aluno;
        EXIT WHEN c_alunos_maiores_18%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Nome: ' || v_aluno.nome || ', Data de Nascimento: ' || TO_CHAR(v_aluno.data_nascimento, 'DD/MM/YYYY'));
    END LOOP;

    CLOSE c_alunos_maiores_18;
END;
/

3.Cursor com filtro por curso:

CREATE OR REPLACE PROCEDURE listar_alunos_por_curso(p_id_curso NUMBER) IS
    CURSOR c_alunos_por_curso IS
        SELECT a.nome
        FROM aluno a
        JOIN matricula m ON a.id_aluno = m.id_aluno
        WHERE m.id_disciplina IN (
            SELECT d.id_disciplina
            FROM disciplina d
            WHERE d.id_curso = p_id_curso
        );

    v_aluno c_alunos_por_curso%ROWTYPE; 
BEGIN
    OPEN c_alunos_por_curso;
    LOOP
        FETCH c_alunos_por_curso INTO v_aluno;
        EXIT WHEN c_alunos_por_curso%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('Nome: ' || v_aluno.nome);
    END LOOP;

    CLOSE c_alunos_por_curso;
END;
/


-- Pacote PKG_DISCIPLINA

1.Procedure de cadastro de disciplina:

CREATE OR REPLACE PROCEDURE cadastrar_disciplina(
    p_nome IN VARCHAR2,
    p_descricao IN CLOB,
    p_carga_horaria IN NUMBER
) IS
BEGIN
    INSERT INTO disciplina (
        id_disciplina,
        nome,
        descricao,
        carga_horaria
    ) VALUES (
        seq_disciplina.NEXTVAL, 
        p_nome,
        p_descricao,
        p_carga_horaria
    );

    COMMIT; -- Confirma a inserção
    DBMS_OUTPUT.PUT_LINE('Disciplina cadastrada com sucesso: ' || p_nome);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK; -- Desfaz a inserção em caso de erro
        DBMS_OUTPUT.PUT_LINE('Erro ao cadastrar disciplina: ' || SQLERRM);
END;
/

2. Cursor para total de alunos por disciplina:

CREATE OR REPLACE PROCEDURE listar_total_alunos_por_disciplina IS
    CURSOR c_total_alunos IS
        SELECT d.id_disciplina, d.nome, COUNT(m.id_aluno) AS total_alunos
        FROM disciplina d
        JOIN matricula m ON d.id_disciplina = m.id_disciplina
        GROUP BY d.id_disciplina, d.nome
        HAVING COUNT(m.id_aluno) > 10;
    
    v_id_disciplina disciplina.id_disciplina%TYPE;
    v_nome disciplina.nome%TYPE;
    v_total_alunos NUMBER;
BEGIN
    OPEN c_total_alunos;
    LOOP
        FETCH c_total_alunos INTO v_id_disciplina, v_nome, v_total_alunos;
        EXIT WHEN c_total_alunos%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Disciplina: ' || v_nome || ' | Total de Alunos: ' || v_total_alunos);
    END LOOP;
    
    CLOSE c_total_alunos;
END;
/

3.Cursor com média de idade por disciplina:

CREATE OR REPLACE PROCEDURE calcular_media_idade_por_disciplina(
    p_id_disciplina IN NUMBER
) IS
    CURSOR c_media_idade IS
        SELECT AVG(MONTHS_BETWEEN(SYSDATE, a.data_nascimento) / 12) AS media_idade
        FROM aluno a
        JOIN matricula m ON a.id_aluno = m.id_aluno
        WHERE m.id_disciplina = p_id_disciplina;
    
    v_media_idade NUMBER;
BEGIN
    OPEN c_media_idade;
    FETCH c_media_idade INTO v_media_idade;
    CLOSE c_media_idade;
    
    IF v_media_idade IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Média de idade dos alunos na disciplina com ID ' || p_id_disciplina || ': ' || v_media_idade || ' anos');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Nenhum aluno encontrado para a disciplina com ID ' || p_id_disciplina);
    END IF;
END;
/

4.Procedure para listar alunos de uma disciplina:

CREATE OR REPLACE PROCEDURE listar_alunos_por_disciplina(
    p_id_disciplina IN NUMBER
) IS
    CURSOR c_alunos IS
        SELECT a.nome
        FROM aluno a
        JOIN matricula m ON a.id_aluno = m.id_aluno
        WHERE m.id_disciplina = p_id_disciplina;
        
    v_nome_aluno aluno.nome%TYPE;
BEGIN
    OPEN c_alunos;
    LOOP
        FETCH c_alunos INTO v_nome_aluno;
        EXIT WHEN c_alunos%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Aluno: ' || v_nome_aluno);
    END LOOP;
    CLOSE c_alunos;
END;
/


-- Pacote PKG_PROFESSOR

1.Cursor para total de turmas por professor:

CREATE OR REPLACE PROCEDURE listar_professores_com_mais_de_uma_turma IS
    CURSOR c_turmas_por_professor IS
        SELECT p.nome, COUNT(t.id_turma) AS total_turmas
        FROM professor p
        JOIN turma t ON p.id_professor = t.id_professor
        GROUP BY p.nome
        HAVING COUNT(t.id_turma) > 1;
    
    v_nome_professor professor.nome%TYPE;
    v_total_turmas NUMBER;
BEGIN
    OPEN c_turmas_por_professor;
    LOOP
        FETCH c_turmas_por_professor INTO v_nome_professor, v_total_turmas;
        EXIT WHEN c_turmas_por_professor%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Professor: ' || v_nome_professor || ' - Total de turmas: ' || v_total_turmas);
    END LOOP;
    CLOSE c_turmas_por_professor;
END;
/

2.Function para total de turmas de um professor:

CREATE OR REPLACE FUNCTION total_turmas_professor(
    p_id_professor IN NUMBER
) RETURN NUMBER IS
    v_total_turmas NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_total_turmas
    FROM turma
    WHERE id_professor = p_id_professor;
    
    RETURN v_total_turmas;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0; 
    WHEN OTHERS THEN
        RAISE; 
END;
/

3.Function para professor de uma disciplina:

CREATE OR REPLACE FUNCTION professor_disciplina(
    p_id_disciplina IN NUMBER
) RETURN VARCHAR2 IS
    v_nome_professor professor.nome%TYPE;
BEGIN
    SELECT p.nome
    INTO v_nome_professor
    FROM professor p
    JOIN turma t ON p.id_professor = t.id_professor
    WHERE t.id_disciplina = p_id_disciplina;
    
    RETURN v_nome_professor;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 'Nenhum professor encontrado para esta disciplina';
    WHEN OTHERS THEN
        RAISE; 
END;
/
