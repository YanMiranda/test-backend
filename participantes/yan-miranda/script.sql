DROP TABLE IF EXISTS tb_transacoes;
DROP TABLE IF EXISTS tb_clientes;

CREATE UNLOGGED TABLE tb_clientes (
    cli_id SERIAL PRIMARY KEY,
    cli_limite INTEGER NOT NULL,
    cli_saldo INTEGER NOT NULL
);

CREATE UNLOGGED TABLE tb_transacoes (
    tra_id SERIAL PRIMARY KEY,
    cli_id INTEGER NOT NULL,
    tra_valor INTEGER NOT NULL,
    tra_tipo CHAR(1) NOT NULL,
    tra_descricao VARCHAR(10) NOT NULL,
    tra_realizada_em TIMESTAMP NOT NULL
);

CREATE INDEX idx_transacoes_cliente_data ON tb_transacoes (cli_id, tra_realizada_em DESC);

INSERT INTO tb_clientes (cli_id, cli_limite, cli_saldo) VALUES
(1, 100000, 0),
(2, 80000, 0),
(3, 1000000, 0),
(4, 10000000, 0),
(5, 500000, 0);

CREATE OR REPLACE FUNCTION create_transaction(
    p_cliente_id INTEGER,
    p_valor INTEGER,
    p_descricao VARCHAR,
    p_tipo VARCHAR
) RETURNS TABLE (status VARCHAR, novo_saldo INTEGER, limite INTEGER) AS $$
DECLARE
v_saldo INTEGER;
    v_limite INTEGER;
    v_valor_ajustado INTEGER;
BEGIN
    IF p_tipo = 'd' THEN
        v_valor_ajustado := -p_valor;
ELSE
        v_valor_ajustado := p_valor;
END IF;

UPDATE tb_clientes
SET cli_saldo = cli_saldo + v_valor_ajustado
WHERE cli_id = p_cliente_id
  AND (p_tipo = 'c' OR (cli_saldo + v_valor_ajustado) >= -cli_limite)
    RETURNING cli_saldo, cli_limite INTO v_saldo, v_limite;

IF FOUND THEN
        INSERT INTO tb_transacoes (cli_id, tra_valor, tra_tipo, tra_descricao, tra_realizada_em)
        VALUES (p_cliente_id, p_valor, p_tipo, p_descricao, NOW());

RETURN QUERY SELECT 'O'::VARCHAR, v_saldo, v_limite;
RETURN;
END IF;

SELECT cli_limite, cli_saldo INTO v_limite, v_saldo
FROM tb_clientes
WHERE cli_id = p_cliente_id;

IF NOT FOUND THEN
        RETURN QUERY SELECT 'N'::VARCHAR, 0, 0;
ELSE
        RETURN QUERY SELECT 'I'::VARCHAR, v_saldo, v_limite;
END IF;
END;
$$ LANGUAGE plpgsql;