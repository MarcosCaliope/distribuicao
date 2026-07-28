module Relatorios
  # Formato único de saída pra qualquer relatório: título + cabeçalhos de coluna + linhas já
  # formatadas pra exibição. Tanto a view HTML compartilhada (app/views/relatorios/tabela.html.erb)
  # quanto o renderizador de PDF (Relatorios::TabelaPdf) consomem esse mesmo formato — é o que
  # no legado era uma tabela de staging por tela, copiada e colada em cada uma; aqui é um só.
  Dataset = Struct.new(:titulo, :subtitulo, :colunas, :linhas, keyword_init: true)
end
