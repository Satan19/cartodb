<div class="CDB-Text Dialog-header u-inner">
  <div class="Dialog-headerIcon Dialog-headerIcon--neutral">
    <i class="CDB-IconFont CDB-IconFont-defaultUser"></i>
  </div>
  <h2 class="Dialog-headerTitle">
    <%= _t('components.modals.password-confirmation.modal-title') %>
  </h2>
  <p class="Dialog-headerText">
    <%= _t('components.modals.password-confirmation.modal-description') %>
  </p>
</div>

<div class="CDB-Text Dialog-body">
  <form action="#" method="POST" class="Form-row Form-row--centered has-label">
    <div class="Form-rowLabel">
      <label class="Form-label" for="password_confirmation"><%= _t('components.modals.password-confirmation.form.password-label') %></label>
    </div>
    <div class="Form-rowData">
      <input type="password" id="password_confirmation" name="password_confirmation" class="CDB-InputText CDB-Text Form-input Form-input--long js-password" value=""/>
    </div>
  </form>
</div>

<div class="Dialog-footer u-inner">
  <button type="button" class="CDB-Button CDB-Button--secondary js-cancel">
    <span class="CDB-Button-Text CDB-Text is-semibold CDB-Size-small u-upperCase">
      <%= _t('components.modals.password-confirmation.actions.cancel') %>
    </span>
  </button>
  <button class="CDB-Button CDB-Button--primary js-ok<%= isConfirmDisabled ? ' is-disabled' : ''%>">
    <span class="CDB-Button-Text CDB-Text is-semibold CDB-Size-small u-upperCase">
      <%= _t('components.modals.password-confirmation.actions.confirm') %>
    </span>
  </button>
</div>
