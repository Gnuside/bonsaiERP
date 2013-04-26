# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
class IncomePresenter < Resubject::Presenter
  currency :balance, precision: 2

  def income_payment
    IncomePayment.new(account_id: id, date: Date.today, amount: 0)
  end

  def income_devolution
    IncomeDevolution.new(account_id: id, date: Date.today, amount: 0)
  end

  def payments
    present AccountLedgerQuery.new.payments_ordered(id), AccountLedgerPresenter
  end

  def payments_devolutions
    present to_model.payments_devolutions.includes(:account_to).order('date  desc, id desc'), AccountLedgerPresenter
  end

  def interests
    present to_model.interests, AccountLedgerPresenter
  end

  def balance?
    to_model.balance > 0
  end

  def has_error_label
    "<span class='label label-important' data-toggle='tooltip' title='Corrija los errores'>ERROR</span>".html_safe if to_model.has_error?
  end

  def state_tag
    html = case state
    when "draft" then span_label('borrador')
    when "approved" then span_label('aprovado', 'label-info')
    when "paid" then span_label('pagado', 'label-success')
    when "nulled" then span_label('anulado', 'label-important')
    end

    html.html_safe
  end

  def due_date_tag
    d = ""
    if is_approved?
      css = ( today > to_model.due_date ) ? "text-error" : ""
      d = "<span class='muted'>Vence el:</span> "
      d << "<span class='i #{css}'><i class='icon-time'></i> "
      d << l(to_model.due_date)
      d << "</span>"
    end
    d.html_safe
  end

  def pendent_conciliations
    if ledgers.pendent.any?
      html = <<-EOS
      <p class="help-block">
        Los cobros y devoluciones con
        <span class="label label-warning"><i class="icon-warning-sign"></i> Pendiente</span>
        necesitan verificación o anulación
      </p>
      EOS

      html.html_safe
    end
  end

  include UsersModulePresenter

  # To load methods related to the Transaction  model
  Transaction.transaction_columns.each do |m|
    define_method m do
      to_model.send(m)
    end
  end


private
  def today
    @today ||= Date.today
  end

  def span_label(txt, css="")
    "<span class='label #{css}'>#{txt}</span>"
  end
end
