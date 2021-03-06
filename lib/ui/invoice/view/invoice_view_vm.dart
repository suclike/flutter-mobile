import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/redux/client/client_actions.dart';
import 'package:invoiceninja_flutter/redux/ui/ui_actions.dart';
import 'package:invoiceninja_flutter/ui/app/dialogs/error_dialog.dart';
import 'package:invoiceninja_flutter/ui/invoice/invoice_screen.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:redux/redux.dart';
import 'package:invoiceninja_flutter/redux/invoice/invoice_actions.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/ui/invoice/view/invoice_view.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/ui/app/snackbar_row.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoiceViewScreen extends StatelessWidget {
  static const String route = '/invoice/view';
  const InvoiceViewScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, InvoiceViewVM>(
      converter: (Store<AppState> store) {
        return InvoiceViewVM.fromStore(store);
      },
      builder: (context, vm) {
        return InvoiceView(
          viewModel: vm,
        );
      },
    );
  }
}

class InvoiceViewVM {
  final CompanyEntity company;
  final InvoiceEntity invoice;
  final ClientEntity client;
  final Function(BuildContext, EntityAction) onActionSelected;
  final Function(BuildContext, [InvoiceItemEntity]) onEditPressed;
  final Function(BuildContext) onClientPressed;
  final Function(BuildContext) onRefreshed;
  final Function onBackPressed;
  final bool isSaving;
  final bool isDirty;

  InvoiceViewVM({
    @required this.company,
    @required this.invoice,
    @required this.client,
    @required this.onActionSelected,
    @required this.onEditPressed,
    @required this.onBackPressed,
    @required this.onClientPressed,
    @required this.isSaving,
    @required this.isDirty,
    @required this.onRefreshed,
  });

  factory InvoiceViewVM.fromStore(Store<AppState> store) {
    final state = store.state;
    final invoice = state.invoiceState.map[state.invoiceUIState.selectedId];
    final client = store.state.clientState.map[invoice.clientId];

    Future<Null> _handleRefresh(BuildContext context) {
      final Completer<InvoiceEntity> completer = Completer<InvoiceEntity>();
      store.dispatch(LoadInvoice(completer: completer, invoiceId: invoice.id));
      return completer.future.then((_) {
        Scaffold.of(context).showSnackBar(SnackBar(
            content: SnackBarRow(
              message: AppLocalization.of(context).refreshComplete,
            )));
      });
    }

    Future<Null> _viewPdf(BuildContext context) async {
      final localization = AppLocalization.of(context);
      String url;
      bool useWebView;

      if (Theme.of(context).platform == TargetPlatform.iOS) {
        url = invoice.invitationSilentLink;
        useWebView = true;
      } else {
        url = 'https://docs.google.com/viewer?url=' +
            invoice.invitationDownloadLink;
        useWebView = false;
      }

      if (await canLaunch(url)) {
        await launch(url, forceSafariVC: useWebView, forceWebView: useWebView);
      } else {
        throw '${localization.anErrorOccurred}';
      }
    }

    return InvoiceViewVM(
        company: state.selectedCompany,
        isSaving: state.isSaving,
        isDirty: invoice.isNew,
        invoice: invoice,
        client: client,
        onEditPressed: (BuildContext context, [InvoiceItemEntity invoiceItem]) {
          final Completer<InvoiceEntity> completer =
              new Completer<InvoiceEntity>();
          store.dispatch(EditInvoice(
              invoice: invoice,
              context: context,
              completer: completer,
              invoiceItem: invoiceItem));
          completer.future.then((invoice) {
            Scaffold.of(context).showSnackBar(SnackBar(
                    content: SnackBarRow(
                  message:
                      AppLocalization.of(context).successfullyUpdatedInvoice,
                )));
          });
        },
        onRefreshed: (context) => _handleRefresh(context),
        onBackPressed: () =>
            store.dispatch(UpdateCurrentRoute(InvoiceScreen.route)),
        onClientPressed: (BuildContext context) {
          store.dispatch(ViewClient(clientId: client.id, context: context));
        },
        onActionSelected: (BuildContext context, EntityAction action) {
          final Completer<Null> completer = new Completer<Null>();
          String message;
          switch (action) {
            case EntityAction.pdf:
              _viewPdf(context);
              break;
            case EntityAction.markSent:
              store.dispatch(MarkSentInvoiceRequest(completer, invoice.id));
              message =
                  AppLocalization.of(context).successfullyMarkedInvoiceAsSent;
              break;
            case EntityAction.emailInvoice:
              store.dispatch(EmailInvoiceRequest(completer, invoice.id));
              message = AppLocalization.of(context).successfullyEmailedInvoice;
              break;
            case EntityAction.archive:
              store.dispatch(ArchiveInvoiceRequest(completer, invoice.id));
              message = AppLocalization.of(context).successfullyArchivedInvoice;
              break;
            case EntityAction.delete:
              store.dispatch(DeleteInvoiceRequest(completer, invoice.id));
              message = AppLocalization.of(context).successfullyDeletedInvoice;
              break;
            case EntityAction.restore:
              store.dispatch(RestoreInvoiceRequest(completer, invoice.id));
              message = AppLocalization.of(context).successfullyRestoredInvoice;
              break;
          }
          if (message != null) {
            return completer.future.then((_) {
              if ([EntityAction.archive, EntityAction.delete]
                  .contains(action)) {
                Navigator.of(context).pop(message);
              } else {
                Scaffold.of(context).showSnackBar(SnackBar(
                        content: SnackBarRow(
                      message: message,
                    )));
              }
            }).catchError((Object error) {
              showDialog<ErrorDialog>(
                  context: context,
                  builder: (BuildContext context) {
                    return ErrorDialog(error);
                  });
            });
          }
        });
  }
}
