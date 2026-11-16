import ambiente.{type Ambiente}
import enigma.{type Enigma, type ErroEnigma, RequisitosAusentes, RespostaIncorreta}
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string
import jogador.{type Jogador, Jogador}
import objeto.{type Objeto}
import sgleam/check
import texto

/// Estado completo da simulação.
///
/// Campos:
/// - `jogador`: o pesquisador (inventário, vida e localização).
/// - `ambientes`: as salas com seus objetos e enigmas ainda pendentes.
pub type Jogo {
  Jogo(jogador: Jogador, ambientes: List(Ambiente))
}

/// Situação da partida.
///
/// - `EmAndamento`: o jogador ainda está no laboratório e com vida.
/// - `Fugiu`: o jogador saiu do laboratório.
/// - `Derrotado`: os pontos de vida chegaram a zero.
pub type Situacao {
  EmAndamento
  Fugiu
  Derrotado
}

/// Cria o jogo inicial: jogador na Recepção, sem itens, com as três
/// salas intactas.
pub fn novo_jogo(nome: String) -> Jogo {
  Jogo(
    jogador: jogador.novo_jogador(nome, ambiente.nome_recepcao),
    ambientes: [
      ambiente.sala_recepcao(),
      ambiente.sala_auditoria(),
      ambiente.sala_servidores(),
    ],
  )
}

/// Devolve a situação da partida (fuga tem prioridade sobre derrota).
pub fn situacao(estado: Jogo) -> Situacao {
  case
    estado.jogador.localizacao == ambiente.nome_fora,
    estado.jogador.pontos_de_vida
  {
    True, _ -> Fugiu
    False, pv if pv <= 0 -> Derrotado
    False, _ -> EmAndamento
  }
}

/// Devolve True enquanto o jogador não possui o registro autêntico, ou
/// seja, enquanto o bloqueio de emergência está ativo.
pub fn bloqueio_ativo(estado: Jogo) -> Bool {
  !jogador.tem_item(estado.jogador.inventario, enigma.item_registro)
}

/// Devolve a mensagem de encerramento correspondente à situação.
/// Para `EmAndamento`, devolve "".
pub fn mensagem_final(estado: Jogo) -> String {
  case situacao(estado) {
    Fugiu -> "Você escapou do laboratório levando os registros autênticos!"
    Derrotado -> "Seus pontos de vida acabaram. Fim de jogo."
    EmAndamento -> ""
  }
}

/// Devolve o ambiente onde o jogador está, ou `None` se a localização
/// não corresponde a nenhuma sala.
pub fn sala_atual(estado: Jogo) -> Option(Ambiente) {
  ambiente.buscar_ambiente(estado.ambientes, estado.jogador.localizacao)
}

/// Aplica `acao` à sala atual; se não houver sala atual, devolve o estado
/// com uma mensagem de erro. Função de ordem superior usada pelas ações.
fn com_sala(
  estado: Jogo,
  acao: fn(Ambiente) -> #(Jogo, String),
) -> #(Jogo, String) {
  case sala_atual(estado) {
    Some(sala) -> acao(sala)
    None -> #(estado, "Localização desconhecida.")
  }
}

/// Texto do estado do bloqueio de emergência.
fn texto_bloqueio(estado: Jogo) -> String {
  case bloqueio_ativo(estado) {
    True -> "Bloqueio de emergência: ATIVO"
    False -> "Bloqueio de emergência: DESATIVADO"
  }
}

/// Descreve a sala atual (objetos e saídas) e o estado do bloqueio.
/// O estado do jogo não muda.
pub fn explorar_sala(estado: Jogo) -> #(Jogo, String) {
  com_sala(estado, fn(sala: Ambiente) {
    #(
      estado,
      ambiente.explorar(sala, estado.jogador) <> "\n" <> texto_bloqueio(estado),
    )
  })
}

/// Mostra o inventário e os pontos de vida. O estado não muda.
pub fn consultar_inventario(estado: Jogo) -> #(Jogo, String) {
  #(
    estado,
    jogador.listar_inventario(estado.jogador.inventario)
      <> "\nPontos de vida: "
      <> int.to_string(estado.jogador.pontos_de_vida),
  )
}

/// Texto com os requisitos de um enigma ("" se não houver).
fn requisitos_txt(requisitos: List(String)) -> String {
  case requisitos {
    [] -> ""
    _ -> "\nRequisitos: " <> string.join(requisitos, ", ")
  }
}

/// Mostra o enigma pendente da sala atual. O estado não muda.
pub fn examinar_enigmas(estado: Jogo) -> #(Jogo, String) {
  com_sala(estado, fn(sala: Ambiente) {
    case ambiente.enigma_pendente(sala) {
      None -> #(estado, "Nenhum enigma pendente nesta sala.")
      Some(pendente) -> #(
        estado,
        "Enigma: " <> pendente.descricao <> requisitos_txt(pendente.requisitos),
      )
    }
  })
}

/// Mostra a `n`-ésima pista (a partir de 1) do enigma pendente da sala
/// atual. O estado não muda.
pub fn pedir_dica(estado: Jogo, n: Int) -> #(Jogo, String) {
  com_sala(estado, fn(sala: Ambiente) {
    case ambiente.enigma_pendente(sala) {
      None -> #(estado, "Nenhum enigma pendente nesta sala.")
      Some(pendente) ->
        case enigma.pista_n(pendente.pistas, n) {
          Some(pista) -> #(estado, "Pista " <> int.to_string(n) <> ": " <> pista)
          None -> #(
            estado,
            "Não existe a pista número " <> int.to_string(n) <> ".",
          )
        }
    }
  })
}

/// Mensagem exibida ao interagir com um objeto: coletáveis informam a
/// coleta e mostram a descrição; objetos de leitura mostram o texto.
fn mensagem_interacao(obj: Objeto) -> String {
  case obj.estado == "coletavel" {
    True -> "Você coletou: " <> obj.nome <> ".\n" <> obj.descricao
    False -> obj.descricao
  }
}

/// Interage com o objeto `nome` da sala atual. Objetos coletáveis vão
/// para o inventário e saem da sala; objetos de leitura permanecem.
/// Se o objeto não existe, o estado permanece igual.
pub fn interagir_objeto(estado: Jogo, nome: String) -> #(Jogo, String) {
  com_sala(estado, fn(sala: Ambiente) {
    case objeto.buscar_objeto(sala.objetos, nome) {
      None -> #(
        estado,
        "Não há nenhum objeto chamado \"" <> nome <> "\" aqui.",
      )
      Some(obj) -> {
        let novo_jogador = objeto.interagir(obj, estado.jogador)
        let nova_sala = case obj.estado == "coletavel" {
          True -> ambiente.remover_objeto(sala, obj.nome)
          False -> sala
        }
        let novo_estado =
          Jogo(
            jogador: novo_jogador,
            ambientes: ambiente.substituir_ambiente(estado.ambientes, nova_sala),
          )
        #(novo_estado, mensagem_interacao(obj))
      }
    }
  })
}

/// Tenta resolver o enigma pendente da sala atual com `resposta`.
/// - Sucesso: aplica o efeito e remove o enigma da sala.
/// - Resposta incorreta: o jogador perde 10 pontos de vida.
/// - Requisitos ausentes: nada muda e a mensagem lista o que falta.
pub fn resolver(estado: Jogo, resposta: String) -> #(Jogo, String) {
  com_sala(estado, fn(sala: Ambiente) {
    case ambiente.enigma_pendente(sala) {
      None -> #(estado, "Não há enigmas pendentes nesta sala.")
      Some(pendente) ->
        tratar_tentativa(
          estado,
          sala,
          pendente,
          enigma.tentar_resolver(pendente, resposta, estado.jogador),
        )
    }
  })
}

/// Converte o resultado de uma tentativa em novo estado e mensagem.
fn tratar_tentativa(
  estado: Jogo,
  sala: Ambiente,
  pendente: Enigma,
  resultado: Result(Jogador, ErroEnigma),
) -> #(Jogo, String) {
  case resultado {
    Ok(novo_jogador) -> {
      let nova_sala = ambiente.remover_enigma_resolvido(sala)
      #(
        Jogo(
          jogador: novo_jogador,
          ambientes: ambiente.substituir_ambiente(estado.ambientes, nova_sala),
        ),
        pendente.mensagem_sucesso,
      )
    }
    Error(RespostaIncorreta) -> {
      let penalizado = jogador.perder_vida(estado.jogador, 10)
      #(
        Jogo(..estado, jogador: penalizado),
        "Resposta incorreta! Você perdeu 10 pontos de vida. Restam: "
          <> int.to_string(penalizado.pontos_de_vida),
      )
    }
    Error(RequisitosAusentes(faltantes)) -> #(
      estado,
      "Você ainda não reuniu: " <> string.join(faltantes, ", ") <> ".",
    )
  }
}

/// Pares (destino, item exigido para entrar).
fn exigencias() -> List(#(String, String)) {
  [
    #(ambiente.nome_auditoria, enigma.cartao_nivel_1),
    #(ambiente.nome_servidores, enigma.cartao_nivel_2),
    #(ambiente.nome_saida, enigma.item_registro),
  ]
}

/// Devolve o item necessário para ir a `destino`, ou `None` se o acesso
/// é livre.
pub fn item_exigido(destino: String) -> Option(String) {
  buscar_exigencia(exigencias(), destino)
}

/// Procura `destino` na lista de exigências (recursão estrutural).
fn buscar_exigencia(
  pares: List(#(String, String)),
  destino: String,
) -> Option(String) {
  case pares {
    [] -> None
    [#(nome, item), ..resto] ->
      case texto.iguais(nome, destino) {
        True -> Some(item)
        False -> buscar_exigencia(resto, destino)
      }
  }
}

/// Move o jogador para `destino`, se for uma saída da sala atual e o
/// jogador possuir o item exigido. Ir para a Saída com o registro
/// autêntico encerra a simulação com fuga.
pub fn mover_para(estado: Jogo, destino: String) -> #(Jogo, String) {
  com_sala(estado, fn(sala: Ambiente) {
    case ambiente.achar_saida(sala.saidas, destino) {
      None -> #(
        estado,
        "Não há passagem para \""
          <> destino
          <> "\" a partir daqui. Saídas: "
          <> string.join(sala.saidas, ", ")
          <> ".",
      )
      Some(nome_destino) ->
        case item_exigido(nome_destino) {
          Some(item) ->
            case jogador.tem_item(estado.jogador.inventario, item) {
              True -> efetivar_movimento(estado, nome_destino)
              False -> #(
                estado,
                "Acesso negado: é necessário possuir \"" <> item <> "\".",
              )
            }
          None -> efetivar_movimento(estado, nome_destino)
        }
    }
  })
}

/// Move o jogador para `nome_destino` (já validado) e descreve o
/// resultado.
fn efetivar_movimento(estado: Jogo, nome_destino: String) -> #(Jogo, String) {
  case texto.iguais(nome_destino, ambiente.nome_saida) {
    True -> {
      let novo = Jogo(..estado, jogador: jogador.mover(estado.jogador, ambiente.nome_fora))
      #(
        novo,
        "O bloqueio cede e a porta se abre. Você atravessa a saída do laboratório!",
      )
    }
    False -> {
      let novo = Jogo(..estado, jogador: jogador.mover(estado.jogador, nome_destino))
      #(novo, "Você segue para: " <> nome_destino <> ".\n" <> explorar_sala(novo).1)
    }
  }
}

/// Testes de `novo_jogo`, `situacao` e `bloqueio_ativo`.
pub fn novo_jogo_examples() {
  let j = novo_jogo("Ana")
  check.eq(j.jogador.localizacao, "Recepção")
  check.eq(j.jogador.inventario, [])
  check.eq(situacao(j), EmAndamento)
  check.eq(bloqueio_ativo(j), True)
  check.eq(mensagem_final(j), "")
  let morto = Jogo(..j, jogador: Jogador(..j.jogador, pontos_de_vida: 0))
  check.eq(situacao(morto), Derrotado)
  let fora = Jogo(..j, jogador: jogador.mover(j.jogador, ambiente.nome_fora))
  check.eq(situacao(fora), Fugiu)
}

/// Testes de `explorar_sala`, `consultar_inventario` e `examinar_enigmas`.
pub fn consultas_examples() {
  let j = novo_jogo("Ana")
  check.eq(
    explorar_sala(j).1,
    ambiente.sala_recepcao().descricao
      <> "\nObjetos: Nota Adesiva, Rainha de Ouros\nSaídas: Auditoria\nBloqueio de emergência: ATIVO",
  )
  check.eq(
    consultar_inventario(j).1,
    "Inventário vazio.\nPontos de vida: 100",
  )
  check.eq(
    examinar_enigmas(j).1,
    "Enigma: " <> enigma.enigma_cesar().descricao,
  )
}

/// Testes de `pedir_dica`.
pub fn pedir_dica_examples() {
  let j = novo_jogo("Ana")
  check.eq(
    pedir_dica(j, 1).1,
    "Pista 1: A Nota Adesiva da recepção traz um código de 4 letras.",
  )
  check.eq(pedir_dica(j, 9).1, "Não existe a pista número 9.")
}

/// Testes de `interagir_objeto` (coleta, leitura e objeto inexistente).
pub fn interagir_objeto_examples() {
  let j0 = novo_jogo("Ana")
  let #(j1, msg) = interagir_objeto(j0, "nota adesiva")
  check.eq(j1.jogador.inventario, ["Nota Adesiva"])
  check.eq(string.contains(msg, "PDLQ"), True)
  check.eq(
    interagir_objeto(j1, "Nota Adesiva").1,
    "Não há nenhum objeto chamado \"Nota Adesiva\" aqui.",
  )
  check.eq(j0.jogador.inventario, [])
}

/// Testes de `resolver`: erro, requisitos e sucesso.
pub fn resolver_examples() {
  let j0 = novo_jogo("Ana")
  let #(erro, msg_erro) = resolver(j0, "ABCD")
  check.eq(erro.jogador.pontos_de_vida, 90)
  check.eq(erro.jogador.inventario, [])
  check.eq(
    msg_erro,
    "Resposta incorreta! Você perdeu 10 pontos de vida. Restam: 90",
  )
  let #(ok, _) = resolver(j0, "main")
  check.eq(ok.jogador.inventario, [enigma.cartao_nivel_1])
  check.eq(examinar_enigmas(ok).1, "Nenhum enigma pendente nesta sala.")
  check.eq(resolver(ok, "MAIN").1, "Não há enigmas pendentes nesta sala.")
}

/// Testes de `item_exigido`.
pub fn item_exigido_examples() {
  check.eq(item_exigido("auditoria"), Some(enigma.cartao_nivel_1))
  check.eq(item_exigido("Servidores"), Some(enigma.cartao_nivel_2))
  check.eq(item_exigido("saida"), Some(enigma.item_registro))
  check.eq(item_exigido("Recepção"), None)
}

/// Testes de `mover_para`: sem acesso, passagem inexistente e com acesso.
pub fn mover_para_examples() {
  let j0 = novo_jogo("Ana")
  check.eq(
    mover_para(j0, "Auditoria").1,
    "Acesso negado: é necessário possuir \"Cartão de Acesso Nível 1\".",
  )
  check.eq(
    mover_para(j0, "Servidores").1,
    "Não há passagem para \"Servidores\" a partir daqui. Saídas: Auditoria.",
  )
  let #(j1, _) = resolver(j0, "MAIN")
  let #(j2, _) = mover_para(j1, "auditoria")
  check.eq(j2.jogador.localizacao, "Auditoria")
  let #(j3, _) = mover_para(j2, "Servidores")
  check.eq(j3.jogador.localizacao, "Auditoria")
}
