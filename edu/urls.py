from django.contrib import admin
from django.urls import path, include  # Include is needed to include app URLs
from django.contrib.auth import views as auth_views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('login/', auth_views.LoginView.as_view(template_name='school/login.html'), name='login'),
    path('school/', include('school.urls')),
    path('student/', include(('student.urls', 'student'), namespace='student')),  
  # Include school app URLs here
]
