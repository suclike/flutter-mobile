import 'package:invoiceninja_flutter/ui/app/list_filter.dart';
import 'package:invoiceninja_flutter/ui/app/list_filter_button.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:flutter/material.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/ui/client/client_list_vm.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/redux/client/client_actions.dart';
import 'package:invoiceninja_flutter/ui/app/app_drawer_vm.dart';
import 'package:invoiceninja_flutter/ui/app/app_bottom_bar.dart';

class ClientScreen extends StatelessWidget {
  static const String route = '/client';

  @override
  Widget build(BuildContext context) {
    final store = StoreProvider.of<AppState>(context);
    final localization = AppLocalization.of(context);

    return Scaffold(
      appBar: AppBar(
        title: ListFilter(
          entityType: EntityType.client,
          onFilterChanged: (value) {
            store.dispatch(FilterClients(value));
          },
        ),
        actions: [
          ListFilterButton(
            entityType: EntityType.client,
            onFilterPressed: (String value) {
              store.dispatch(FilterClients(value));
            },
          ),
        ],
      ),
      drawer: AppDrawerBuilder(),
      body: ClientListBuilder(),
      bottomNavigationBar: AppBottomBar(
        entityType: EntityType.client,
        onSelectedSortField: (value) {
          store.dispatch(SortClients(value));
        },
        sortFields: [
          ClientFields.name,
          ClientFields.balance,
          ClientFields.updatedAt,
        ],
        onSelectedState: (EntityState state, value) {
          store.dispatch(FilterClientsByState(state));
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColorDark,
        onPressed: () => store.dispatch(EditClient(client: ClientEntity(), context: context)),
        child: Icon(Icons.add, color: Colors.white,),
        tooltip: localization.newClient,
      ),
    );
  }
}
