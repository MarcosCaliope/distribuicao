class RelaxTipoTituloOnTitulos < ActiveRecord::Migration[8.0]
  def change
    # Um título pode ficar irregular por espécie não cadastrada (código 21 —
    # ver FrmCadTitulos.labelIrreg), caso em que o legado grava tipo_tit='*'
    # sem nenhum tipo real associado. Aqui isso vira tipo_titulo_id nulo.
    change_column_null :titulos, :tipo_titulo_id, true
  end
end
