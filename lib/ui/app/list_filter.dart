import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:invoiceninja_flutter/data/models/entities.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:redux/redux.dart';

class ListFilter extends StatelessWidget {
  final EntityType entityType;
  final String filter;
  final Function(String) onFilterChanged;

  const ListFilter({
    this.entityType,
    this.filter,
    this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localization = AppLocalization.of(context);

    return StoreConnector<AppState, AppState>(
      converter: (Store<AppState> store) => store.state,
      builder: (BuildContext context, state) {
        final listUIState = state.getListState(entityType);
        final bool enableDarkMode = state.uiState.enableDarkMode;
        return listUIState.filter == null
            ? Text(localization.lookup(entityType.plural.toString()))
            : Container(
                padding: const EdgeInsets.only(left: 8.0),
                height: 38.0,
                margin: EdgeInsets.only(bottom: 2.0),
                decoration: BoxDecoration(
                    color: listUIState.filter != null &&
                            listUIState.filter.isNotEmpty
                        ? enableDarkMode
                            ? Colors.yellow.shade900
                            : Colors.yellow.shade200
                        : Theme.of(context).backgroundColor,
                    border: Border.all(
                        color: enableDarkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                        width: 1.0),
                    borderRadius: BorderRadius.circular(6.0)),
                child: TextField(
                  decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.search),
                      ),
                      border: InputBorder.none,
                      hintText: localization.filter),
                  autofocus: true,
                  autocorrect: false,
                  onChanged: (value) => onFilterChanged(value),
                ),
              );
      },
    );
  }
}
