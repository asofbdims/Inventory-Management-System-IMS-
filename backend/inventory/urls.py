from django.urls import path
from .api import (
    AuthViewSet,
    CentreViewSet,
    StockRegisterViewSet,
    ItemMasterViewSet,
    SCIFormViewSet,
    DestinationViewSet,
    GRNRegisterViewSet,
    TransferViewSet,
    DocumentMasterViewSet,
    LogViewSet,
)

urlpatterns = [
    # Auth endpoints
    path('login/', AuthViewSet.as_view({'post': 'login'})),
    path('credentials/', AuthViewSet.as_view({'post': 'credentials'})),
    path('reset_password/', AuthViewSet.as_view({'post': 'reset_password'})),
    
    # Centre endpoints
    path('centres/tree/', CentreViewSet.as_view({'get': 'tree'})),
    path('centres/flat/', CentreViewSet.as_view({'get': 'flat'})),
    path('centres/create/', CentreViewSet.as_view({'post': 'create'})),
    path('centres/<int:pk>/update/', CentreViewSet.as_view({'put': 'update'})),
    path('centres/<int:pk>/delete/', CentreViewSet.as_view({'delete': 'destroy'})),
    
    # Stock endpoints
    path('stock/list/', StockRegisterViewSet.as_view({'get': 'list'})),
    path('stock/create/', StockRegisterViewSet.as_view({'post': 'create'})),
    path('stock/<int:pk>/update/', StockRegisterViewSet.as_view({'put': 'update'})),
    path('stock/<int:pk>/delete/', StockRegisterViewSet.as_view({'delete': 'destroy'})),
    path('stock/import/', StockRegisterViewSet.as_view({'post': 'import_data'})),
    
    # Item endpoints
    path('items/list/', ItemMasterViewSet.as_view({'get': 'list'})),
    path('items/create/', ItemMasterViewSet.as_view({'post': 'create'})),
    path('items/<int:pk>/update/', ItemMasterViewSet.as_view({'put': 'update'})),
    path('items/<int:pk>/delete/', ItemMasterViewSet.as_view({'delete': 'destroy'})),
    
    # SCI Form endpoints
    path('sci-forms/submit/', SCIFormViewSet.as_view({'post': 'submit'})),
    path('sci-forms/list/', SCIFormViewSet.as_view({'get': 'list'})),
    path('sci-forms/export/', SCIFormViewSet.as_view({'get': 'export'})),
    path('sci-forms/<int:pk>/approve/', SCIFormViewSet.as_view({'post': 'approve'})),
    path('sci-forms/<int:pk>/reject/', SCIFormViewSet.as_view({'post': 'reject'})),
    
    # Destination endpoints
    path('destinations/list/', DestinationViewSet.as_view({'get': 'list'})),
    path('destinations/create/', DestinationViewSet.as_view({'post': 'create'})),
    
    # GRN endpoints
    path('grn/list/', GRNRegisterViewSet.as_view({'get': 'list'})),
    path('grn/create/', GRNRegisterViewSet.as_view({'post': 'create'})),
    
    # Transfer endpoints
    path('transfers/list/', TransferViewSet.as_view({'get': 'list'})),
    path('transfers/create/', TransferViewSet.as_view({'post': 'create'})),
    
    # Document endpoints
    path('documents/list/', DocumentMasterViewSet.as_view({'get': 'list'})),
    path('documents/create/', DocumentMasterViewSet.as_view({'post': 'create'})),
    
    # Log endpoints
    path('logs/list/', LogViewSet.as_view({'get': 'list'})),
]