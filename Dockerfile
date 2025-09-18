# ---------------------------
# BUILD STAGE
# ---------------------------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy csproj and restore as distinct layers
COPY *.csproj ./
RUN dotnet restore

# Copy everything and build
COPY . .
RUN dotnet publish -c Release -o /app/out

# ---------------------------
# RUNTIME STAGE
# ---------------------------
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app

# Expose port 80 (matches your deployment.yaml)
EXPOSE 80

# Copy published output from build stage
COPY --from=build /app/out .

# Set the URL binding (same as your manifest’s env var)
ENV ASPNETCORE_URLS=http://+:80

# Start the app
ENTRYPOINT ["dotnet", "WebApp.dll"]
