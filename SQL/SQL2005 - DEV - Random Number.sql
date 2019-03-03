Cast(100 * RAND(Checksum(Newid())) + 1 AS INT) AS Rnd -- Numeros de 0 a 100
Cast(5   * RAND(Checksum(Newid())) + 1 AS INT) AS Rnd -- Numeros de 0 a 5