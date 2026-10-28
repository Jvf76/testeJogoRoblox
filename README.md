# Monster Egg Heist

Protótipo multiplayer em Luau. O mapa, as bases, os ovos, os monstros e a interface são gerados pelos scripts. Os modelos low-poly são placeholders originais feitos com primitivas do Roblox.

## Abrir no Roblox Studio

1. Crie uma experiência Baseplate vazia.
2. Com Rojo instalado, execute `rojo serve default.project.json` nesta pasta e conecte o plugin Rojo do Studio. O arquivo `default.project.json` sincroniza os scripts. Também é possível gerar um arquivo independente com `rojo build default.project.json --output MonsterEggHeist.rbxlx` e abri-lo diretamente no Studio.
3. Sem Rojo, crie um `ModuleScript` chamado `Config` em `ReplicatedStorage` com `src/shared/Config.lua`, um `Script` chamado `Game` em `ServerScriptService` com `src/server/Game.server.lua`, e um `LocalScript` chamado `HUD` em `StarterPlayer > StarterPlayerScripts` com `src/client/HUD.client.lua`.
4. O jogo roda em arquivo local sem DataStore, mas o progresso dessa sessão não é salvo. Para testar persistência, publique uma experiência de teste e habilite **Game Settings > Security > Enable Studio Access to API Services**.
5. Teste com **Start Server** e dois jogadores. Controles: `E` nos prompts para coletar, incubar, melhorar ou roubar; `G` ou botão **Soltar** para largar o ovo.

## Mapa em desenvolvimento

A versão atual está em `MonsterEggHeist-map-v3.rbxlx`. Ela traz chão verde com relevo em pinos, área dourada, paredes altas quadriculadas, cercas nas seis bases laterais e mar azul. O cenário usa peças simples, sem malhas ou texturas externas, e nove ovos ativos no máximo. Os rótulos dos ovos só aparecem de perto. Os personagens nascem voltados para o centro.

Durante a partida, o mouse gira a câmera diretamente. Segure `Alt` para soltar o cursor e clicar na interface.

O vídeo fornecido foi usado para estudar escala, visibilidade da rota e posição das bases; os nomes, cores, formas e objetos do cenário são originais deste projeto. O mapa ainda precisa de uma rodada de ajuste de arte, iluminação e navegação com mais jogadores.

## Ciclo implementado

Ovos surgem nas três regiões, com pesos configuráveis e mais chances de raridades altas nas áreas perigosas. Um jogador carrega um ovo por vez; ao entrar na própria base, ele começa a incubar. Após o tempo da raridade, uma criatura aleatória da mesma categoria aparece e gera moedas. Monstros patrulham e perseguem portadores; ao alcançá-los, o ovo cai. Outros jogadores podem roubar criaturas expostas quando o escudo da base termina. O proprietário recebe aviso e pode comprar proteção ou melhoria de renda.

O servidor decide spawn, posse, sorteio, renda, gasto e roubo. O cliente só solicita soltar o ovo. Dados são carregados e salvos com `UpdateAsync`, tentativas repetidas e salvamento periódico. A incubação usa horário absoluto para poder continuar após reconexão.

## Verificado no Roblox Studio

- O arquivo `MonsterEggHeist.rbxlx` foi aberto e executado em teste local.
- Mapa, base, ovos e HUD apareceram; a coleta de um ovo atualizou o HUD e mostrou o botão Soltar.
- Um guardião derrubou um ovo transportado.
- Um ovo Raro entrou na incubadora, o temporizador de 30 segundos terminou, nasceu Sombrico e o saldo aumentou.
- O DataStore não está disponível nesse arquivo local; o jogo continuou na sessão sem persistir os dados.
- A conexão ao servidor Rojo local pelo plugin do Studio retornou `HTTP request timed out` neste ambiente. O arquivo gerado pelo Rojo funcionou no Studio.

## Testes ainda necessários no Studio

- Verificar spawn e coleta em PC e celular; confirmar limite de um ovo e botão Soltar.
- Levar ovos de cada região até a base e verificar contagem regressiva, revelação e renda.
- Usar dois jogadores: testar roubo antes/depois do escudo, cooldown, limite da base e notificações.
- Aproximar um portador dos monstros e confirmar perda do ovo; verificar navegação em torno de obstáculos.
- Publicar em experiência de teste com acesso à API e confirmar persistência após sair e entrar. Testar falha de DataStore sem substituir dados antigos.
- Verificar posicionamento da interface em diferentes tamanhos de tela.

Os testes multiplayer, de celular e de persistência exigem uma experiência de teste publicada e ainda não foram feitos.
