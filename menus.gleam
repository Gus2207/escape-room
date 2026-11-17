import gleam/int
import gleam/io
import gleam/list
import gleam/string
import jogador
import jogo.{type Jogo, EmAndamento, Fugiu}
import sgleam/check

/// Opções do menu principal.
///
/// - `Explorar`: descreve a sala atual.
/// - `Inventario`: mostra os itens coletados pelo jogador.
/// - `Enigmas`: mostra o enigma pendente da sala.
/// - `Interagir(nome)`: interage com o objeto `nome`.
/// - `Resolver(resposta)`: tenta resolver o enigma da sala.
/// - `IrPara(destino)`: move o jogador para outra sala.
/// - `PedirDica(n)`: mostra a n-ésima pista do enigma da sala.
/// - `Sair`: encerra a simulação.
pub type MainMenu {
  Explorar
  Inventario
  Enigmas
  Interagir(String)
  Resolver(String)
  IrPara(String)
  PedirDica(Int)
  Sair
}

/// Exibe o menu principal e as regras de entrada no terminal
/// (camada de apresentação).
pub fn display_main_menu() -> Nil {
  io.println("\n--- MENU PRINCIPAL (MODO INTERATIVO) ---")
  io.println("1. Inicie a partida guardando o estado em uma variável:")
  io.println("   let j = menus.iniciar(\"SeuNome\")")
  io.println("2. Avance passo a passo atualizando o estado `j`:")
  io.println("   let j = menus.m1(j)               -> Explorar ambiente")
  io.println("   let j = menus.m2(j)               -> Consultar inventário")
  io.println("   let j = menus.m3(j)               -> Examinar enigmas")
  io.println("   let j = menus.m4(j, \"Objeto\")     -> Interagir com um objeto")
  io.println("   let j = menus.m5(j, \"RESPOSTA\")   -> Resolver o enigma da sala")
  io.println("   let j = menus.m6(j, \"Destino\")    -> Ir para outra sala")
  io.println("   let j = menus.m7(j, 1)            -> Pedir a pista número n")
  io.println("   let j = menus.exit(j)             -> Encerrar simulação")
  io.println("\n--- REGRAS DE FORMATAÇÃO DAS ENTRADAS ---")
  io.println(
    "- Objetos e Saídas (m4, m6): digite EXATAMENTE como aparecem na tela, respeitando maiúsculas, minúsculas e acentos (ex: \"Nota Adesiva\", \"Auditoria\", \"Saída\").",
  )
  io.println(
    "- Respostas de Enigmas (m5): digite tudo em LETRAS MAIÚSCULAS e SEM acentos (ex: \"MAIN\").",
  )
}

/// Inicia uma nova partida para `nome`, exibe o menu de comandos e a
/// descrição inicial da Recepção, e devolve o estado inicial `Jogo`.
pub fn iniciar(nome: String) -> Jogo {
  let estado = jogo.novo_jogo(nome)
  display_main_menu()
  io.println("\n--- INÍCIO DA EXPLORAÇÃO ---")
  io.println(jogo.explorar_sala(estado).1)
  estado
}

/// Executa "Explorar ambiente", imprime o resultado e devolve o novo estado.
pub fn m1(estado: Jogo) -> Jogo {
  mostrar(estado, Explorar)
}

/// Executa "Consultar inventário", imprime o resultado e devolve o novo estado.
pub fn m2(estado: Jogo) -> Jogo {
  mostrar(estado, Inventario)
}

/// Executa "Examinar enigmas", imprime o resultado e devolve o novo estado.
pub fn m3(estado: Jogo) -> Jogo {
  mostrar(estado, Enigmas)
}

/// Executa "Interagir com o objeto `nome_objeto`", imprime o resultado e
/// devolve o novo estado.
pub fn m4(estado: Jogo, nome_objeto: String) -> Jogo {
  mostrar(estado, Interagir(nome_objeto))
}

/// Executa "Resolver o enigma da sala com `resposta`", imprime o resultado
/// e devolve o novo estado.
pub fn m5(estado: Jogo, resposta: String) -> Jogo {
  mostrar(estado, Resolver(resposta))
}

/// Executa "Ir para `destino`", imprime o resultado e devolve o novo estado.
pub fn m6(estado: Jogo, destino: String) -> Jogo {
  mostrar(estado, IrPara(destino))
}

/// Executa "Pedir a pista número `n`" (a partir de 1), imprime o resultado
/// e devolve o novo estado.
pub fn m7(estado: Jogo, n: Int) -> Jogo {
  mostrar(estado, PedirDica(n))
}

/// Executa "Encerrar simulação", imprime o aviso e devolve o estado atual.
pub fn exit(estado: Jogo) -> Jogo {
  mostrar(estado, Sair)
}

/// Executa uma opção do menu sobre o estado e devolve o novo estado e a
/// mensagem resultante. É pura: não imprime nada. Depois que o jogo
/// termina com fuga, só `Sair` é aceita.
pub fn executar(estado: Jogo, opcao: MainMenu) -> #(Jogo, String) {
  case jogo.situacao(estado), opcao {
    EmAndamento, Explorar -> jogo.explorar_sala(estado)
    EmAndamento, Inventario -> jogo.consultar_inventario(estado)
    EmAndamento, Enigmas -> jogo.examinar_enigmas(estado)
    EmAndamento, Interagir(nome) -> jogo.interagir_objeto(estado, nome)
    EmAndamento, Resolver(resposta) -> jogo.resolver(estado, resposta)
    EmAndamento, IrPara(destino) -> jogo.mover_para(estado, destino)
    EmAndamento, PedirDica(n) -> jogo.pedir_dica(estado, n)
    _, Sair -> #(estado, "Simulação encerrada.")
    Fugiu, _ -> #(
      estado,
      "A simulação já terminou. " <> jogo.mensagem_final(estado),
    )
  }
}

/// Aplica uma lista de opções em sequência e devolve o estado final
/// (usa `list.fold`).
pub fn executar_roteiro(estado: Jogo, opcoes: List(MainMenu)) -> Jogo {
  list.fold(opcoes, estado, fn(acc: Jogo, opcao: MainMenu) {
    executar(acc, opcao).0
  })
}

/// Devolve o texto da chamada de menu equivalente à opção, por exemplo
/// `menus.m4(j, "Nota Adesiva")`.
pub fn descrever_opcao(opcao: MainMenu) -> String {
  case opcao {
    Explorar -> "menus.m1(j)"
    Inventario -> "menus.m2(j)"
    Enigmas -> "menus.m3(j)"
    Interagir(nome) -> "menus.m4(j, \"" <> nome <> "\")"
    Resolver(resposta) -> "menus.m5(j, \"" <> resposta <> "\")"
    IrPara(destino) -> "menus.m6(j, \"" <> destino <> "\")"
    PedirDica(n) -> "menus.m7(j, " <> int.to_string(n) <> ")"
    Sair -> "menus.exit(j)"
  }
}

/// Executa a opção, imprime o comando e a mensagem no terminal e devolve
/// o novo estado (camada de apresentação).
pub fn mostrar(estado: Jogo, opcao: MainMenu) -> Jogo {
  let #(novo, mensagem) = executar(estado, opcao)
  io.println("\n> " <> descrever_opcao(opcao))
  io.println(mensagem)
  novo
}

/// Executa e imprime uma lista de opções em sequência (recursão em
/// cauda) e devolve o estado final.
pub fn mostrar_roteiro(estado: Jogo, opcoes: List(MainMenu)) -> Jogo {
  case opcoes {
    [] -> estado
    [opcao, ..resto] -> mostrar_roteiro(mostrar(estado, opcao), resto)
  }
}

/// Roteiro completo da partida (usado nos testes unitários), da Recepção
/// até a fuga, incluindo uma tentativa incorreta sem perda de vida.
pub fn roteiro_fuga() -> List(MainMenu) {
  [
    Explorar,
    Interagir("Nota Adesiva"),
    Interagir("Rainha de Ouros"),
    Enigmas,
    PedirDica(1),
    Resolver("ABCD"),
    Resolver("MAIN"),
    IrPara("Auditoria"),
    Interagir("Manual de Protocolo"),
    Interagir("Trilha de Auditoria"),
    Interagir("Rei de Copas"),
    Interagir("Valete de Espadas"),
    Resolver("RAFAEL 02, THIAGO 03, FERNANDA 04"),
    IrPara("Servidores"),
    Interagir("Ás de Paus"),
    Interagir("Placa de Bronze"),
    Resolver("RAINHA REI VALETE AS"),
    Inventario,
    IrPara("Saída"),
  ]
}

/// Testes de `descrever_opcao`.
pub fn descrever_opcao_examples() {
  check.eq(descrever_opcao(Explorar), "menus.m1(j)")
  check.eq(descrever_opcao(Interagir("Rei de Copas")), "menus.m4(j, \"Rei de Copas\")")
  check.eq(descrever_opcao(PedirDica(3)), "menus.m7(j, 3)")
  check.eq(descrever_opcao(Sair), "menus.exit(j)")
}

/// Testes de `executar` (cada variante do menu, a transição de estado e
/// o estado anterior preservado).
pub fn executar_examples() {
  let j0 = jogo.novo_jogo("Ana")
  check.eq(string.contains(executar(j0, Explorar).1, "Nota Adesiva"), True)
  check.eq(executar(j0, Inventario).1, "Inventário vazio.")
  check.eq(string.contains(executar(j0, Enigmas).1, "Enigma:"), True)
  check.eq(string.contains(executar(j0, PedirDica(2)).1, "Pista 2:"), True)
  check.eq(executar(j0, Sair).1, "Simulação encerrada.")
  let j1 = executar(j0, Interagir("Rainha de Ouros")).0
  check.eq(j1.jogador.inventario, ["Rainha de Ouros"])
  check.eq(j0.jogador.inventario, [])
  check.eq(executar(j0, Resolver("ABCD")).0, j0)
  check.eq(
    executar(j0, IrPara("Auditoria")).1,
    "Acesso negado: é necessário possuir \"Cartão de Acesso Nível 1\".",
  )
}

/// Teste da partida completa: a fuga com todos os 8 itens e o bloqueio
/// de ações depois do fim.
pub fn roteiro_fuga_examples() {
  let fim = executar_roteiro(jogo.novo_jogo("Ana"), roteiro_fuga())
  check.eq(jogo.situacao(fim), Fugiu)
  check.eq(jogo.bloqueio_ativo(fim), False)
  check.eq(jogador.contar_itens(fim.jogador.inventario), 8)
  check.eq(fim.jogador.inventario, [
    "Nota Adesiva",
    "Rainha de Ouros",
    "Cartão de Acesso Nível 1",
    "Rei de Copas",
    "Valete de Espadas",
    "Cartão de Acesso Nível 2",
    "Ás de Paus",
    "Registro Autêntico (Dados Recuperados)",
  ])
  check.eq(
    executar(fim, Explorar).1,
    "A simulação já terminou. Você escapou do laboratório levando os registros autênticos!",
  )
  check.eq(executar(fim, Sair).1, "Simulação encerrada.")
}
