class WidenTipoDocumentoColumns < ActiveRecord::Migration[8.0]
  def change
    # Usamos "CNPJ" (não o "CGC" arcaico do legado) como rótulo — precisa de
    # mais que os 3 caracteres herdados de cad_devedor.tipo_doc/varchar(3).
    change_column :devedores, :tipo_documento, :string, limit: 4
    change_column :titulos, :tipo_documento_devedor, :string, limit: 4
  end
end
