// Copyright eeGeo Ltd (2012-2014), All Rights Reserved

#include "App.h"
#include "AppHost.h"
#include "LatLongAltitude.h"
#include "EegeoWorld.h"
#include "RenderContext.h"
#include "AppInterface.h"
#include "Blitter.h"
#include "EffectHandler.h"
#include "SearchServiceCredentials.h"
#include "GlobeCameraController.h"
#include "RenderCamera.h"
#include "CameraHelpers.h"
#include "PlatformConfig.h"
#include "iOSPlatformConfigBuilder.h"
#include "EegeoWorld.h"
#include "RouteMatchingExampleFactory.h"
#include "RouteSimulationExampleFactory.h"
#include "JpegLoader.h"
#include "iOSPlatformAbstractionModule.h"
#include "ScreenProperties.h"

using namespace Eegeo::iOS;

AppHost::AppHost(
                 const std::string& apiKey,
                 ViewController& viewController,
                 const Eegeo::Rendering::ScreenProperties& screenProperties
                 )
    :m_viewController(viewController)
	,m_pBlitter(NULL)
    ,m_pJpegLoader(NULL)
	,m_piOSLocationService(NULL)
	,m_pWorld(NULL)
	,m_iOSInputBoxFactory()
	,m_iOSKeyboardInputFactory()
	,m_iOSAlertBoxFactory()
	,m_iOSNativeUIFactories(m_iOSAlertBoxFactory, m_iOSInputBoxFactory, m_iOSKeyboardInputFactory)
    ,m_piOSPlatformAbstractionModule(NULL)
	,m_pApp(NULL)
{
	m_piOSLocationService = new iOSLocationService();
	   
    m_pJpegLoader = new Eegeo::Helpers::Jpeg::JpegLoader();
    
    m_piOSPlatformAbstractionModule = new Eegeo::iOS::iOSPlatformAbstractionModule(*m_pJpegLoader, apiKey);

	Eegeo::EffectHandler::Initialise();

	m_pBlitter = new Eegeo::Blitter(1024 * 128, 1024 * 64, 1024 * 32);
	m_pBlitter->Initialise();

	const Eegeo::EnvironmentCharacterSet::Type environmentCharacterSet = Eegeo::EnvironmentCharacterSet::Latin;
    
	Eegeo::Config::PlatformConfig config = Eegeo::iOS::iOSPlatformConfigBuilder(App::GetDevice(), App::IsDeviceMultiCore(), App::GetMajorSystemVersion()).Build();
    
	m_pWorld = new Eegeo::EegeoWorld(apiKey,
                                     *m_piOSPlatformAbstractionModule,
                                     *m_pJpegLoader,
                                     screenProperties,
                                     *m_piOSLocationService,
                                     *m_pBlitter,
                                     m_iOSNativeUIFactories,
                                     environmentCharacterSet,
                                     config,
                                     NULL);
    
	ConfigureExamples(screenProperties);
    
    m_pAppInputDelegate = new AppInputDelegate(*m_pApp, m_viewController, screenProperties.GetScreenWidth(), screenProperties.GetScreenHeight(), screenProperties.GetPixelScale());
    m_pAppLocationDelegate = new AppLocationDelegate(*m_piOSLocationService, m_viewController);
}

AppHost::~AppHost()
{
    delete m_pAppLocationDelegate;
    m_pAppLocationDelegate = NULL;
    
	delete m_pAppInputDelegate;
	m_pAppInputDelegate = NULL;

	DestroyExamples();

	delete m_pApp;
	m_pApp = NULL;

	delete m_pWorld;
	m_pWorld = NULL;

	delete m_piOSLocationService;
	m_piOSLocationService = NULL;
    
    delete m_piOSPlatformAbstractionModule;
    m_piOSPlatformAbstractionModule = NULL;
    
    delete m_pJpegLoader;
    m_pJpegLoader = NULL;

	Eegeo::EffectHandler::Reset();
	Eegeo::EffectHandler::Shutdown();
	m_pBlitter->Shutdown();
	delete m_pBlitter;
	m_pBlitter = NULL;
}

void AppHost::OnResume()
{
	m_pApp->OnResume();
}

void AppHost::OnPause()
{
	m_pApp->OnPause();
}

void AppHost::SetViewportOffset(float x, float y)
{
}

void AppHost::NotifyScreenPropertiesChanged(const Eegeo::Rendering::ScreenProperties& screenProperties)
{
    m_pApp->NotifyScreenPropertiesChanged(screenProperties);
}

void AppHost::Update(float dt)
{
	m_pApp->Update(dt);
}

void AppHost::Draw(float dt)
{
	m_pApp->Draw(dt);
}

void AppHost::ConfigureExamples(const Eegeo::Rendering::ScreenProperties& screenProperties)
{
	m_piOSExampleControllerView = new Examples::iOSExampleControllerView([&m_viewController view]);


	m_pApp = new ExampleApp(m_pWorld, *m_piOSExampleControllerView, screenProperties);

	RegisteriOSSpecificExamples();

	m_piOSExampleControllerView->PopulateExampleList(m_pApp->GetExampleController().GetExampleNames());

	m_pApp->GetExampleController().ActivatePrevious();
}

void AppHost::RegisteriOSSpecificExamples()
{
	m_piOSRouteMatchingExampleViewFactory = new Examples::iOSRouteMatchingExampleViewFactory([&m_viewController view]);


    m_pApp->GetExampleController().RegisterExample(new Examples::RouteMatchingExampleFactory(
                                                                                             *m_pWorld,
                                                                                             *m_piOSRouteMatchingExampleViewFactory,
                                                                                             m_pApp->GetDefaultCameraControllerFactory(),
                                                                                             m_pApp->GetTouchController()
                                                                                             ));

	m_piOSRouteSimulationExampleViewFactory = new Examples::iOSRouteSimulationExampleViewFactory([&m_viewController view]);

	m_pApp->GetExampleController().RegisterExample(new Examples::RouteSimulationExampleFactory(
	        *m_pWorld,
	        m_pApp->GetDefaultCameraControllerFactory(),
            m_pApp->GetTouchController(),
            m_pApp->GetScreenPropertiesProvider(),
	        *m_piOSRouteSimulationExampleViewFactory));
}

void AppHost::DestroyExamples()
{
	delete m_piOSRouteMatchingExampleViewFactory;
	delete m_piOSRouteSimulationExampleViewFactory;

	delete m_piOSExampleControllerView;
}





