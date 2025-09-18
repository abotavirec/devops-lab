# ---------------------------
# BUILD STAGE
# ---------------------------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build

# Build args tell us which project to build
ARG PROJECT_PATH=src/WebApp/WebApp.csproj

# Restore + publish
WORKDIR /src
COPY . .
# Sanity: fail early if the project path is wrong
RUN test -f "$PROJECT_PATH" || (echo "ERROR: PROJECT_PATH '$PROJECT_PATH' not found"; ls -laR /src; exit 2)

# Restore & publish to a deterministic output
RUN dotnet restore "$PROJECT_PATH"
RUN dotnet publish "$PROJECT_PATH" -c Release -o /app/out --no-restore

# ---------------------------
# RUNTIME STAGE
# ---------------------------
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
EXPOSE 80

# App binds to 80 (matches your k8s manifest)
ENV ASPNETCORE_URLS=http://+:80

# Copy published app
COPY --from=build /app/out /app/out

# Project dll name (e.g., virecintelligencevirecwebapp.dll)
ARG PROJECT_DLL=virecintelligencevirecwebappp.dll
ENV PROJECT_DLL=${PROJECT_DLL}

# Start the app
CMD ["sh", "-c", "exec dotnet /app/out/$PROJECT_DLL"]
