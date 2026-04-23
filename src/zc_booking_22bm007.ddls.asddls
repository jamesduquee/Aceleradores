@EndUserText.label: 'Taxi Booking - Consumption'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true

define root view entity ZC_BOOKING_22BM007
  provider contract transactional_query
  as projection on ZI_Booking_22bm007
{
    @UI.facet: [ { id: 'Booking', 
                   purpose: #STANDARD, 
                   type: #IDENTIFICATION_REFERENCE, 
                   label: 'Booking Details', 
                   position: 10 } ]

    @UI.hidden: true
    key booking_uuid,

    @UI: { lineItem:       [ { position: 10, label: 'Booking No.' } ],
           identification: [ { position: 10, label: 'Booking No.' } ],
           selectionField: [ { position: 10 } ] }
    booking_id,

    @UI: { lineItem:       [ { position: 20, label: 'Customer Name' } ],
           identification: [ { position: 20, label: 'Customer Name' } ] }
    @Search.defaultSearchElement: true
    customer_name,

    @UI: { lineItem:       [ { position: 30, label: 'Pickup Location' } ],
           identification: [ { position: 30, label: 'Pickup Location' } ] }
    pickup_location,

    @UI: { lineItem:       [ { position: 40, label: 'Drop Location' } ],
           identification: [ { position: 40, label: 'Drop Location' } ] }
    drop_location,

    @UI: { lineItem:       [ { position: 50, label: 'Status' },
                             { type: #FOR_ACTION, dataAction: 'assignDriver', label: 'Assign Driver' },
                             { type: #FOR_ACTION, dataAction: 'startTrip', label: 'Start Trip' },
                             { type: #FOR_ACTION, dataAction: 'completeTrip', label: 'Complete Trip' } ],
           identification: [ { position: 50, label: 'Status' } ] }
    status,

    @UI: { lineItem:       [ { position: 60, label: 'Booking Date' } ],
           identification: [ { position: 60, label: 'Booking Date' } ] }
    booking_date,

    @UI.identification: [ { position: 70, label: 'Driver ID' } ]
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_Driver_22bm007', element: 'driver_id' } }]
    driver_id,

    @UI.identification: [ { position: 80, label: 'Vehicle' } ]
    vehicle_number,

    @UI.identification: [ { position: 90, label: 'Fare' } ]
    fare_amount,
    
    currency_code,

    /* Association */
    _Driver
}
