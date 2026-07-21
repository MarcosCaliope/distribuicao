class RelaxProtocoloOriginalOnTitulos < ActiveRecord::Migration[8.0]
  def change
    # "id" já é a identidade estável e imutável de um Titulo criado pelo
    # Rails; protocolo_original só é necessário para preservar a proveniência
    # de títulos vindos do legado via ETL (Etapa 7) — por isso passa a ser
    # opcional em vez de obrigatório.
    change_column_null :titulos, :protocolo_original, true
  end
end
