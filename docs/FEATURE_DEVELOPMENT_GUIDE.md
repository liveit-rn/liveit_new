# Panduan Pengembangan Fitur Project LIVEIT

Dokumentasi ini berisi informasi mengenai backend dan panduan langkah demi langkah untuk mengembangkan fitur baru di aplikasi LIVEIT. Panduan ini menggunakan **Fitur Profile** sebagai contoh studi kasus, namun **diimplementasikan dengan meniru struktur Fitur Auth** (karena fitur Auth adalah referensi yang sudah matang).

## 1. Informasi Backend

Backend untuk project ini menggunakan REST API.

- **Base URL**: `https://liveit-api-dev-5jufu.ondigitalocean.app/`
- **Dokumentasi API (Swagger)**: [https://liveit-api-dev-5jufu.ondigitalocean.app/api#/](https://liveit-api-dev-5jufu.ondigitalocean.app/api#/)

## 2. Arsitektur Fitur (Clean Architecture)

Setiap fitur di aplikasi ini (terletak di `lib/features/`) mengikuti pola **Clean Architecture** yang memisahkan kode menjadi tiga lapisan utama:

1.  **Domain**: Lapisan terdalam. Berisi logika bisnis murni, entitas, dan kontrak (interface). Tidak boleh bergantung pada library eksternal (seperti UI atau HTTP client).
2.  **Data**: Implementasi dari kontrak domain. Menangani pengambilan data dari API (Remote) atau penyimpanan lokal.
3.  **Presentation**: Menangani UI dan State Management (menggunakan **BLoC**).

Struktur folder untuk fitur baru (misal: `profile`):

```
lib/features/profile/
├── data/
│   ├── datasources/   (Remote/Local Data Sources)
│   ├── models/        (DTO / JSON Serializable classes)
│   └── repositories/  (Implementasi Repository)
├── domain/
│   ├── entities/      (Dart Classes murni)
│   ├── repositories/  (Interface/Contract)
│   └── usecases/      (Logika bisnis spesifik)
└── presentation/
    ├── bloc/          (BLoC State Management)
    ├── pages/         (Halaman/Screen)
    └── widgets/       (Komponen UI reusable)
```

---

## 3. Langkah-Langkah Membuat Fitur Baru (Studi Kasus: Profile User)

Berikut adalah contoh implementasi fitur Profile yang **ideal**, mengikuti standar coding yang ada di fitur `auth`.

### Langkah 1: Domain Layer (Define the Contract)

Mulailah dengan mendefinisikan apa itu data Anda dan apa yang bisa dilakukan dengannya.

1.  **Entities**: Buat class data murni di `domain/entities/`. Gunakan package `equatable`.
    ```dart
    // domain/entities/profile.dart
    import 'package:equatable/equatable.dart';

    class Profile extends Equatable {
      final String id;
      final String email;
      final String fullName;
      final String? bio;
      final String? avatarUrl;

      const Profile({
        required this.id,
        required this.email,
        required this.fullName,
        this.bio,
        this.avatarUrl,
      });

      @override
      List<Object?> get props => [id, email, fullName, bio, avatarUrl];
    }
    ```

2.  **Repository Interface**: Buat contract di `domain/repositories/`.
    ```dart
    // domain/repositories/profile_repository.dart
    import '../entities/profile.dart';

    abstract class ProfileRepository {
      Future<Profile> getProfile();
      Future<Profile> updateProfile({String? fullName, String? bio});
    }
    ```

3.  **Use Cases**: Buat class untuk setiap aksi spesifik di `domain/usecases/`.
    ```dart
    // domain/usecases/get_profile_usecase.dart
    import '../repositories/profile_repository.dart';
    import '../entities/profile.dart';

    class GetProfileUseCase {
      final ProfileRepository repository;

      GetProfileUseCase(this.repository);

      Future<Profile> call() {
        return repository.getProfile();
      }
    }
    ```

### Langkah 2: Data Layer (Implement the Contract)

Implementasikan bagaimana cara mengambil data dari API.

1.  **Models**: Buat class turunan Entity yang bisa diubah dari/ke JSON di `data/models/`. Gunakan `json_annotation`.
    ```dart
    // data/models/profile_model.dart
    import 'package:json_annotation/json_annotation.dart';
    import '../../domain/entities/profile.dart';

    part 'profile_model.g.dart';

    @JsonSerializable()
    class ProfileModel extends Profile {
      const ProfileModel({
        required super.id,
        required super.email,
        required super.fullName,
        super.bio,
        super.avatarUrl,
      });

      factory ProfileModel.fromJson(Map<String, dynamic> json) => _$ProfileModelFromJson(json);
      Map<String, dynamic> toJson() => _$ProfileModelToJson(this);

      // Mapper methods
      factory ProfileModel.fromEntity(Profile profile) {
        return ProfileModel(
          id: profile.id,
          email: profile.email,
          fullName: profile.fullName,
          bio: profile.bio,
          avatarUrl: profile.avatarUrl,
        );
      }

      Profile toEntity() {
        return Profile(
          id: id,
          email: email,
          fullName: fullName,
          bio: bio,
          avatarUrl: avatarUrl,
        );
      }
    }
    ```

2.  **Data Sources**: Buat class untuk call API di `data/datasources/`. Gunakan `Dio`.
    Perhatikan pola passing `token` sebagai parameter method.

    ```dart
    // data/datasources/profile_remote_datasource.dart
    import 'package:dio/dio.dart';
    import '../models/profile_model.dart';

    abstract class ProfileRemoteDataSource {
      Future<ProfileModel> getProfile(String token);
      Future<ProfileModel> updateProfile(String token, Map<String, dynamic> data);
    }

    class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
      final Dio dio;
      
      ProfileRemoteDataSourceImpl({required this.dio});

      @override
      Future<ProfileModel> getProfile(String token) async {
        // Endpoint contoh, sesuaikan dengan Swagger
        final response = await dio.get(
          '/api/profile', 
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        return ProfileModel.fromJson(response.data);
      }

      @override
      Future<ProfileModel> updateProfile(String token, Map<String, dynamic> data) async {
        final response = await dio.put(
          '/api/profile',
          data: data,
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
        return ProfileModel.fromJson(response.data);
      }
    }
    ```

3.  **Repository Implementation**: Hubungkan datasource dengan domain repository di `data/repositories/`.
    Gunakan `AuthLocalDataSource` untuk mengambil token yang tersimpan.

    ```dart
    // data/repositories/profile_repository_impl.dart
    import '../../domain/repositories/profile_repository.dart';
    import '../../domain/entities/profile.dart';
    import '../datasources/profile_remote_datasource.dart';
    // Import auth datasource untuk akses token
    import '../../auth/data/datasources/auth_local_datasource.dart'; 

    class ProfileRepositoryImpl implements ProfileRepository {
      final ProfileRemoteDataSource remoteDataSource;
      final AuthLocalDataSource localDataSource;

      ProfileRepositoryImpl({
        required this.remoteDataSource,
        required this.localDataSource,
      });

      @override
      Future<Profile> getProfile() async {
        final token = await localDataSource.getAccessToken();
        if (token == null) throw Exception('Unauthorized');
        
        final model = await remoteDataSource.getProfile(token);
        return model.toEntity();
      }

      @override
      Future<Profile> updateProfile({String? fullName, String? bio}) async {
        final token = await localDataSource.getAccessToken();
        if (token == null) throw Exception('Unauthorized');

        final data = <String, dynamic>{};
        if (fullName != null) data['fullName'] = fullName;
        if (bio != null) data['bio'] = bio;

        final model = await remoteDataSource.updateProfile(token, data);
        return model.toEntity();
      }
    }
    ```

### Langkah 3: Dependency Injection (Service Locator)

Daftarkan semua class yang baru dibuat ke `lib/core/injection/injection_container.dart`.

```dart
// lib/core/injection/injection_container.dart

// ... imports

void configureDependencies() {
  // ... dependencies Auth sudah ada
  
  // Profile Data Sources
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(dio: getIt()),
  );

  // Profile Repository
  // Perhatikan kita inject AuthLocalDataSource ke ProfileRepositoryImpl
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      remoteDataSource: getIt(),
      localDataSource: getIt<AuthLocalDataSource>(), 
    ),
  );

  // Profile Use Cases
  getIt.registerLazySingleton(() => GetProfileUseCase(getIt()));

  // Profile BLoC
  getIt.registerFactory(
    () => ProfileBloc(getProfileUseCase: getIt()),
  );
}
```

### Langkah 4: Presentation Layer (UI & State)

Terakhir, buat tampilan dan logika state-nya.

1.  **BLoC**: Buat Event, State, dan Bloc di `presentation/bloc/`.
    - `profile_event.dart`: `GetProfileRequested`
    - `profile_state.dart`: `ProfileInitial`, `ProfileLoading`, `ProfileLoaded(profile)`, `ProfileError(message)`
    - `profile_bloc.dart`:
      ```dart
      // ... imports
      class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
        final GetProfileUseCase getProfileUseCase;

        ProfileBloc({required this.getProfileUseCase}) : super(ProfileInitial()) {
          on<GetProfileRequested>(_onGetProfileRequested);
        }

        Future<void> _onGetProfileRequested(
          GetProfileRequested event, 
          Emitter<ProfileState> emit
        ) async {
          emit(ProfileLoading());
          try {
            final profile = await getProfileUseCase();
            emit(ProfileLoaded(profile));
          } catch (e) {
            emit(ProfileError(e.toString()));
          }
        }
      }
      ```

2.  **Pages**: Buat halaman di `presentation/pages/`. Gunakan `BlocProvider` dan `BlocBuilder`.
    ```dart
    class ProfilePage extends StatelessWidget {
      const ProfilePage({super.key});

      @override
      Widget build(BuildContext context) {
        return BlocProvider(
          create: (context) => getIt<ProfileBloc>()..add(GetProfileRequested()),
          child: Scaffold(
            appBar: AppBar(title: const Text("Profile")),
            body: BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ProfileLoaded) {
                  return Column(
                    children: [
                      // Contoh menampilkan data
                      Text(state.profile.fullName, style: Theme.of(context).textTheme.headlineMedium),
                      Text(state.profile.email),
                    ],
                  );
                }
                if (state is ProfileError) {
                  return Center(child: Text(state.message));
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      }
    }
    ```

## Tips Penting
- **Code Generation**: Jika membuat Model dengan `@JsonSerializable`, jangan lupa jalankan `dart run build_runner build` atau `flutter pub run build_runner build` untuk generate file `.g.dart`.
- **Handling Token**: Fitur selain Auth biasanya membutuhkan token. Gunakan `AuthLocalDataSource` untuk mengambil token di level Repository.
- **Konsistensi**: Selalu ikuti pola penamaan dan struktur folder yang sama.
